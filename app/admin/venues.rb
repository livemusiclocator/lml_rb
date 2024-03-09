ActiveAdmin.register Lml::Venue, as: "Venue" do
  permit_params :name, :address, :location_url, :latitude, :longitude

  filter :name_cont, label: "Name"

  form do |f|
    f.inputs do
      f.input :name
      f.input :address
      f.input :location_url
      f.input :latitude
      f.input :longitude
    end
    f.actions
  end
end
