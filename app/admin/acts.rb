ActiveAdmin.register Lml::Act, as: "Act" do
  permit_params(
    :country,
    :genre_list,
    :location,
    :name,
  )

  filter :name_cont, label: "Name"

  form do |f|
    f.inputs do
      f.input :name
      f.input :country, as: "string"
      f.input :location
      f.input :genre_list
    end
    f.actions
  end
end
