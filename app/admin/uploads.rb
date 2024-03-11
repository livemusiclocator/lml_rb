ActiveAdmin.register Lml::Upload, as: "Upload" do
  permit_params(
    :format,
    :source,
    :content,
  )

  filter :format_cont, label: "Format"
  filter :source_cont, label: "Source"

  index do
    selectable_column
    column :format
    column :source
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :format
      row :source
      row :content do |upload|
        simple_format upload.content
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :format
      f.input :source
      f.input :content
    end
    f.actions
  end

  action_item :reprocess, only: %i[show] do
    link_to "Reprocess", reprocess_admin_upload_path(upload), method: :put
  end

  member_action :reprocess, method: :put do
    resource.process!
    redirect_to resource_path, notice: "Reprocessed"
  end

  controller do
    def create
      super
      resource.process!
    end

    def update
      super
      resource.process!
    end
  end
end
