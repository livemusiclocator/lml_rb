ActiveAdmin.register Lml::Set, as: "Set" do
  permit_params(
    :gig_id,
    :act_id,
    :start_offset_time,
    :stage,
    :duration,
  )

  filter :none

  index do
    selectable_column
    column :gig
    column :act
    column :stage
    column :start_offset_time
    column :duration
    column :created_at do |resource|
      admin_time(resource.created_at)
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :gig
      row :act
      row :stage
      row :start_offset_time
      row :duration
      row :start_at do |resource|
        admin_time(resource.start_at)
      end
      row :start_time do |resource|
        admin_time(resource.start_time)
      end
      row :finish_time do |resource|
        admin_time(resource.finish_time)
      end
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end
  end

  action_item :clone, only: %i[show] do
    link_to(
      "Clone",
      new_admin_set_path(
        gig_id: set.gig_id,
        start_offset: set.start_offset,
      ),
      method: :get,
    )
  end

  form do |f|
    f.inputs do
      f.input :gig_label, label: "Gig"
      f.input :gig_id, as: "hidden"
      f.input :act_label, label: "Act"
      f.input :act_id, as: "hidden"
      f.input :stage
      f.input :start_offset_time, as: :time_picker, label: "Start Time"
      f.input :duration, label: "Duration (mins)"
    end
    script <<~SCRIPT.html_safe
      attachAutocomplete("lml_set_gig", "/gigs/autocomplete", "Select Gig");
      attachAutocomplete("lml_set_act", "/acts/autocomplete", "Select Act");
    SCRIPT
    f.actions
  end

  controller do
    def new
      gig_id = params[:gig_id]
      start_offset = params[:start_offset]

      @set = Lml::Set.new(
        gig_id: gig_id,
        start_offset: start_offset,
      )
    end
  end
end
