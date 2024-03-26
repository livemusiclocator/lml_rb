ActiveAdmin.register Lml::Venue, as: "Venue" do
  permit_params(
    :address,
    :capacity,
    :latitude,
    :location,
    :location_url,
    :longitude,
    :name,
    :postcode,
    :time_zone,
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
      row :website do |resource|
        link_to(resource.website, resource.website, target: "_blank", rel: "noopener noreferrer") if resource.website
      end
      row :capacity
      row :address
      row :postcode
      row :time_zone
      row :location
      row :location_url
      row :latitude
      row :longitude
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

  form do |f|
    f.inputs do
      f.input :name
      f.input :website
      f.input :capacity
      f.input(
        :time_zone,
        as: :select,
        collection: ActiveSupport::TimeZone.country_zones("AU").map(&:name).sort,
      )
      f.input :address
      f.input :postcode
      f.input :location
      f.input :location_url
      f.input :latitude
      f.input :longitude
    end
    f.actions
  end
end
