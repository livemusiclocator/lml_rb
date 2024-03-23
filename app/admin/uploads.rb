ActiveAdmin.register Lml::Upload, as: "Upload" do
  permit_params(
    :content,
    :format,
    :source,
    :time_zone,
    :venue_id,
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
    column :venue
    column :time_zone
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :format
      row :source
      row :venue
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
      f.input(
        :format,
        as: :select,
        collection: Lml::Upload.formats.keys,
      )
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input(
        :time_zone,
        as: :select,
        collection: ActiveSupport::TimeZone.country_zones("AU").map(&:name).sort,
      )
      f.input :source
      f.input :content
    end
    script <<~SCRIPT.html_safe
      attachAutocomplete("lml_upload_venue", "/venues/autocomplete", "Select Venue");
    SCRIPT
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
