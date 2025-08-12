ActiveAdmin.register Lml::Location, as: "Location" do
  # Permitted parameters
  permit_params :internal_identifier, :name, :latitude, :longitude

  # Index page configuration
  index do
    selectable_column
    id_column
    column :internal_identifier
    column :name
    column :latitude
    column :longitude
    column :created_at
    actions
  end

  # Show page configuration
  show do
    attributes_table do
      row :id
      row :internal_identifier
      row :name
      row :latitude
      row :longitude
      row :created_at
      row :updated_at
    end
  end

  # Form configuration
  form do |f|
    f.inputs do
      f.input :internal_identifier
      f.input :name
      f.input :latitude, step: :any
      f.input :longitude, step: :any
    end
    f.actions
  end

  # Filters
  filter :internal_identifier
  filter :name
  filter :latitude
  filter :longitude
  filter :created_at
  filter :updated_at
end
