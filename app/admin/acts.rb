ActiveAdmin.register Lml::Act, as: "Act" do
  permit_params(
    :country,
    :genre_list,
    :location,
    :name,
  )

  filter :name_cont, label: "Name"
  filter :country_cont, label: "Country"
  filter :location_cont, label: "Location"

  index do
    selectable_column
    column :name do |act|
      link_to(act.name, admin_act_path(act))
    end
    column :country
    column :location
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :country
      row :location
      row :genre_list
      row :created_at
      row :updated_at
    end
  end

  sidebar "Links", only: :show do
    ul do
      li link_to "Gigs", admin_gigs_path("q[headline_act_id_eq]" => resource.id)
      li link_to "Sets", admin_sets_path("q[act_id_eq]" => resource.id)
    end
  end

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
