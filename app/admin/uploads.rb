ActiveAdmin.register Lml::Upload, as: "Upload" do
  permit_params(
    :content,
    :format,
    :source,
    :status,
    :time_zone,
    :venue_id,
  )

  filter :format_cont, label: "Format"
  filter :source_cont, label: "Source"

  index do
    selectable_column
    column :created_at do |resource|
      link_to(admin_time(resource.created_at), admin_upload_path(resource))
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    column :format
    column :source
    column :venue
    column :time_zone
    actions
  end

  show do
    attributes_table do
      row :format
      row :source
      row :venue
      row :time_zone
      row :status
      row :error_description
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end

    panel "Gigs" do
      table_for (upload.gig_ids || []) do
        column :link do |id|
          gig = Lml::Gig.find_by(id: id)
          if gig
            link_to gig.name, admin_gig_path(id)
          else
            "deleted gig"
          end
        end
      end
    end

    attributes_table do
      row :content do |upload|
        pre { upload.content }
      end
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
        collection: Lml::Timezone::CANONICAL_TIMEZONES,
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

  action_item :rescrape, only: %i[show] do
    link_to "Rescrape", rescrape_admin_upload_path(upload), method: :put
  end

  member_action :rescrape, method: :put do
    resource.rescrape!
    redirect_to resource_path, notice: "Rescraped"
  end

  controller do
    def new
      @upload = Lml::Upload.new(time_zone: current_admin_user.time_zone)
    end

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
