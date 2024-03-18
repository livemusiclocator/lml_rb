ActiveAdmin.register Lml::Upload, as: "Upload" do
  permit_params(
    :format,
    :source,
    :content,
    :time_zone,
  )

  filter :format_cont, label: "Format"
  filter :source_cont, label: "Source"

  index do
    selectable_column
    column :created_at do |upload|
      link_to(upload.created_at, admin_upload_path(upload))
    end
    column :format
    column :source
    column :time_zone
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :format
      row :source
      row :time_zone
      row :content do |upload|
        pre { upload.content }
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :format, as: :select, collection: Lml::Upload.formats.keys
      f.input :time_zone
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
