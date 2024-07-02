ActiveAdmin.register Lml::Venue, as: "Venue" do
  permit_params(
    :address,
    :capacity,
    :email,
    :lat_lng,
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
  )

  filter :name_cont, label: "Name"
  filter :time_zone_cont, label: "Time Zone"
  filter :location_cont, label: "Location"

  index do
    selectable_column
    column :name do |venue|
      link_to(venue.name, admin_venue_path(venue))
    end
    column :time_zone
    column :location
    column :created_at do |resource|
      admin_time(resource.created_at)
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :time_zone
      row :location
      row :email
      row :phone
      row :address
      row :postcode
      row :website do |resource|
        if resource.website.present?
          link_to(resource.website, resource.website, target: "_blank", rel: "noopener noreferrer")
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
        link_to(
          point,
          "https://maps.google.com/?q=#{point}",
          target: "_blank",
          rel: "noopener noreferrer",
        ) unless point.blank?
      end
      row :vibe
      row :tag_list
      row :notes do |resource|
        pre { resource.notes }
      end
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end
  end

  sidebar "Links", only: :show do
    ul do
      li link_to "Gigs", admin_gigs_path("q[venue_id_eq]" => resource.id)
    end
  end

  action_item :download_gigs, only: [:show] do
    link_to "Download Gigs", download_gigs_admin_venue_path(resource, format: :txt)
  end

  member_action :download_gigs, method: :get do
    send_data(
      Lml::Processors::ClipperSerialiser.new(resource).serialise,
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
    f.inputs do
      f.input :name
      f.input(
        :time_zone,
        as: :select,
        collection: Lml::Timezone::CANONICAL_TIMEZONES,
      )
      f.input :location
      f.input :email, input_html: { type: "email" }
      f.input :phone
      f.input :address
      f.input :postcode
      f.input :website
      f.input :capacity
      f.input :location_url
      f.input :lat_lng
      f.input :vibe
      f.input :tag_list
      f.input :notes, as: :text, input_html: { rows: 5 }
    end
    f.actions
  end
end
