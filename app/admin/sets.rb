ActiveAdmin.register Lml::Set, as: "Set" do
  permit_params(
    :gig_id,
    :act_id,
    :start_time,
    :finish_time,
  )

  filter :none

  index do
    selectable_column
    column :gig
    column :act
    column :start_time
    column :finish_time
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :gig
      row :act
      row :start_time
      row :finish_time
      row :created_at
      row :updated_at
    end
  end

  action_item :clone, only: %i[show] do
    link_to "Clone", new_admin_set_path(gig_id: set.gig_id, start_time: set.start_time, end_time: set.finish_time), method: :get
  end

  form do |f|
    f.inputs do
      f.input :gig_label, label: "Gig"
      f.input :gig_id, as: "hidden"
      f.input :act_label, label: "Act"
      f.input :act_id, as: "hidden"
      f.input :start_time, as: :datetime_picker
      f.input :finish_time, as: :datetime_picker
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
      start_time = params[:start_time]
      finish_time = params[:finish_time]

      @set = Lml::Set.new(
        gig_id: gig_id,
        start_time: start_time,
        finish_time: finish_time,
      )
    end
  end
end
