ActiveAdmin.register Lml::Venue, as: "Venue" do
  permit_params(
    :name,
    :address,
    :location,
    :location_url,
    :latitude,
    :longitude,
  )

  filter :name_cont, label: "Name"
  filter :location_cont, label: "Location"

  index do
    selectable_column
    column :name do |venue|
      link_to(venue.name, admin_venue_path(venue))
    end
    column :location
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :address
      row :location
      row :location_url
      row :latitude
      row :longitude
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :address
      f.input :location
      f.input :location_url
      f.input :latitude
      f.input :longitude
    end
    f.actions
  end
end
