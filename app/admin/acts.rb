ActiveAdmin.register Lml::Act, as: "Act" do
  permit_params :name, :country, :location

  filter :name_cont, label: "Name"

  form do |f|
    f.inputs do
      f.input :name
      f.input :country, as: "string"
      f.input :location
    end
    f.actions
  end
end
