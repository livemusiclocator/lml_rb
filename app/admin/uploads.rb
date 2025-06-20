ActiveAdmin.register Lml::Upload, as: "Upload" do
  permit_params(
    :content,
    :source,
    :status,
    :venue_id,
  )

  filter :source_cont, label: "Source"

  index do
    selectable_column
    column :created_at do |resource|
      link_to(admin_time(resource.created_at), admin_upload_path(resource))
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    column :source
    column :venue
    actions
  end

  show do
    attributes_table do
      row :source
      row :venue
      row :status
      row :error_description
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
      row :content do |upload|
        pre { upload.content }
      end
    end
  end

  sidebar "Links", only: :show do
    ul do
      li link_to "Gigs", admin_gigs_path("q[upload_id_eq]" => resource.id)
    end
  end

  form do |f|

    f.inputs do
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input :source
      f.input :content
      div do
        link_to(
          "Detailed documentation on content formatting",
          "https://docs.google.com/document/d/1o-3VA5yghojXBiSHworXDHJfGp7NOUZgbpnGN1lhzio/edit?tab=t.0#heading=h.lqx2443ai69m",
        )
      end
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
