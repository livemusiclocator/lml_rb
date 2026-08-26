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

    # Derived data, so it is shown but never edited - neither column is in permit_params, so the
    # form cannot reach them either. Written by Lml::VenueImport; see
    # doc/google_sheets_venue_import.md.
    panel "Google Places" do
      if resource.address_components.blank?
        para "Not resolved through the Places API. Venues added by hand have none until an " \
             "import matches them."
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
    end
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
