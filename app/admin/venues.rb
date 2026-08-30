# frozen_string_literal: true

ActiveAdmin.register Lml::Venue, as: "Venue" do
  permit_params(
    :address,
    :capacity,
    :email,
    :facebook_url,
    :instagram_url,
    :lat_lng,
    :lga,
    :location,
    :location_url,
    :name,
    :notes,
    :phone,
    :postcode,
    :tag_list,
    :time_zone,
    :vibe,
    :website,
    :admin_user_id
  )

  batch_action :assign_to_admin_user, form: -> { { admin_user_id: Lml::AdminUser.order(:username).map { |u| [u.username, u.id] } } } do |ids, inputs|
    Lml::Venue.where(id: ids).update_all(admin_user_id: inputs[:admin_user_id])
    redirect_to collection_path, notice: "Venues assigned to admin user."
  end

  batch_action :unassign_from_admin_user do |ids|
    Lml::Venue.where(id: ids).update_all(admin_user_id: nil)
    redirect_to collection_path, notice: "Venues unassigned."
  end

  filter :name_cont, label: "Name"
  filter :time_zone_cont, label: "Time Zone"
  filter :location_cont, label: "Location"
  filter :with_admin_user, label: "Researcher", as: :select, collection: -> { [["Unassigned", "none"]] + Lml::AdminUser.order(:username).map { |u| [u.username, u.id] } }

  index do
    selectable_column
    column :name do |venue|
      link_to(venue.name, admin_venue_path(venue))
    end
    column :time_zone
    column :location
    column "Validated location" do |venue|
      if venue.location_record
        link_to venue.location_record.name, admin_location_path(venue.location_record)
      else
        span "No match", class: "status_tag orange"
      end
    end
    column "Researcher" do |resource|
      resource.admin_user&.username
    end
    column :created_at do |resource|
      admin_time(resource.created_at)
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    actions
  end

  show do
    # rubocop:disable Metrics/BlockLength
    attributes_table do
      row :id
      row :name
      row :time_zone
      row :location
      row :admin_user do |resource|
        resource.admin_user&.username
      end
      row :email
      row :phone
      row :address
      row :postcode
      row :lga
      row :website do |resource|
        if resource.website.present?
          link_to(resource.website, resource.website, target: "_blank", rel: "noopener noreferrer")
        end
      end
      row :instagram_url do |resource|
        if resource.instagram_url.present?
          link_to(resource.instagram_url, resource.instagram_url, target: "_blank", rel: "noopener noreferrer")
        end
      end
      row :facebook_url do |resource|
        if resource.facebook_url.present?
          link_to(resource.facebook_url, resource.facebook_url, target: "_blank", rel: "noopener noreferrer")
        end
      end
      row :capacity
      row :location_url do |resource|
        if resource.location_url.present?
          link_to(resource.location_url, resource.location_url, target: "_blank", rel: "noopener noreferrer")
        end
      end
      row :lat_lng do |resource|
        point = resource.lat_lng
        unless point.blank?
          link_to(
            point,
            "https://maps.google.com/?q=#{point}",
            target: "_blank",
            rel: "noopener noreferrer",
          )
        end
      end
      row :vibe
      row :tag_list
      row :notes do |resource|
        pre { resource.notes }
      end
      row "Matched Location Record" do |venue|
        if venue.location_record
          link_to venue.location_record.name, admin_location_path(venue.location_record)
        else
          "No matching location found"
        end
      end
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end
    # rubocop:enable Metrics/BlockLength

    # Derived data, so it is shown but never edited - none of these columns is in permit_params, so
    # the form cannot reach them either. Written by Lml::VenueImport and Lml::VenuePlaceLookup; see
    # doc/google_sheets_venue_import.md.
    panel "Google Places" do
      if resource.google_place_marker?
        para do
          text_node "The last lookup did not settle on one place: "
          span resource.google_place_id, class: "status_tag orange"
        end
        para "Nothing was written onto the venue. Correcting the name or address here and then " \
             "forcing another lookup through the admin API is the way forward.", class: "inline-hints"
      elsif resource.address_components.blank?
        para "Not resolved through the Places API. Venues added by hand have none until an " \
             "import matches them, or until somebody looks one up here."
      else
        attributes_table_for resource do
          row("Place ID") { resource.google_place_id }
          row("Resolved name") { resource.address_components["name"] }
          row("Business status") do
            if resource.closed_permanently?
              span resource.google_business_status, class: "status_tag red"
            else
              resource.google_business_status
            end
          end
          # The subset that venue matching is actually done on, which is what explains why an
          # import matched this venue or created a new one beside it.
          row("Matched on") { pretty_json(resource.address_identity) }
          row("All components") { pretty_json(resource.address_components) }
        end
      end

      # A real form with an authenticity token, not `link_to method: :post` - ActiveAdmin 3.5 ships
      # no rails-ujs, so that renders a GET and silently does nothing. See CLAUDE.md.
      form action: lookup_place_admin_venue_path(resource), method: :post do
        text_node hidden_field_tag(:authenticity_token, form_authenticity_token)

        # One billable Places request per click, so the button closes the moment the column holds
        # an answer of any kind. Asking again is deliberately awkward - it is `force` on the admin
        # API's POST /v1/admin/venues/:id/place_lookup, and nothing in here.
        if resource.google_place_id.present?
          input type: :submit, value: "Look up in Google Places", disabled: "disabled"
          para "Already answered. Asking Google again costs another request, so it is only " \
               "available through the admin API, with force.", class: "inline-hints"
        else
          input type: :submit, value: "Look up in Google Places"
          para "Searches Places for this venue's name and address. Fills in only the columns " \
               "that are still blank.", class: "inline-hints"
        end
      end
    end
  end

  member_action :lookup_place, method: :post do
    outcome = Lml::VenuePlaceLookup.call(resource)

    redirect_to admin_venue_path(resource), notice: {
      Lml::VenuePlaceLookup::MATCHED => "Matched one place. Blank columns filled in from Google.",
      Lml::VenuePlaceLookup::NO_MATCH => "Places found nothing for that name and address.",
      Lml::VenuePlaceLookup::AMBIGUOUS => "Places found more than one candidate, so nothing was written.",
      Lml::VenuePlaceLookup::SKIPPED => "Already looked up - nothing spent.",
    }.fetch(outcome)
  rescue Lml::GooglePlacesApiClient::Error => e
    redirect_to admin_venue_path(resource), alert: "Places API error: #{e.message}"
  end

  sidebar "Links", only: :show do
    ul do
      li link_to "Gigs", admin_gigs_path("q[venue_id_eq]" => resource.id, "order" => "created_at_desc")
      li link_to "Uploads", admin_uploads_path("q[venue_id_eq]" => resource.id)
    end
  end

  action_item :download_gigs, only: [:show] do
    link_to "Download Gigs", download_gigs_admin_venue_path(resource, format: :txt)
  end

  member_action :download_gigs, method: :get do
    send_data(
      Lml::Processors::ClipperSerialiser.for_venue(resource),
      type: "application/txt",
      filename: "gigs_#{resource.name.downcase.gsub(" ", "_")}.txt",
    )
  end

  action_item :generate_upload, only: [:show] do
    link_to "Generate Upload", generate_upload_admin_venue_path(resource)
  end

  member_action :generate_upload, method: :get do
    content = Lml::Processors::ClipperSerialiser.new(resource).serialise
    upload = Lml::Upload.find_by(venue: resource)
    if upload
      upload.update!(content: content)
    else
      upload = Lml::Upload.create!(
        content: content,
        venue: resource,
      )
    end
    redirect_to edit_admin_upload_path(upload)
  end

  form do |f|
    # One input past Max, the same way the show block is.
    # rubocop:disable Metrics/BlockLength
    f.inputs do
      f.input :name
      f.input(
        :time_zone,
        as: :select,
        collection: Lml::Timezone::CANONICAL_TIMEZONES,
      )
      f.input :location, hint: "Should ideally match a Location's internal_identifier (case insensitive)"
      f.input(
        :admin_user,
        as: :select,
        collection: Lml::AdminUser.order(:username).map { |u| [u.username, u.id] }
      )
      f.input :email, input_html: { type: "email" }
      f.input :phone
      f.input :address
      f.input :postcode
      f.input :lga, hint: "Local government area, eg City of Yarra"
      f.input :website
      f.input :instagram_url
      f.input :facebook_url
      f.input :capacity
      f.input :location_url
      f.input :lat_lng
      f.input :vibe
      f.input :tag_list
      f.input :notes, as: :text, input_html: { rows: 5 }
    end
    # rubocop:enable Metrics/BlockLength
    f.actions
  end
end
