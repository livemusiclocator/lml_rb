ActiveAdmin.register Lml::Gig, as: "Gig" do
  permit_params(
    :date,
    :status,
    :finish_time,
    :headline_act_id,
    :name,
    :start_time,
    :venue_id,
  )

  filter :none

  index do
    selectable_column
    id_column
    column :name
    column :date
    column :venue
    column :headline_act
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :date
      row :venue
      row :headline_act
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input :headline_act_label, label: "Headline Act"
      f.input :headline_act_id, as: "hidden"
      f.input :date, as: :date_picker
      f.input :status, as: :select, collection: Lml::Gig.statuses.keys
      f.input :start_time, as: :datetime_picker
      f.input :finish_time, as: :datetime_picker
    end
    script <<~SCRIPT.html_safe
      attachAutocomplete("lml_gig_venue", "/venues/autocomplete", "Select Venue");
      attachAutocomplete("lml_gig_headline_act", "/acts/autocomplete", "Select Headline Act");
    SCRIPT
    f.actions
  end

  controller do
    def new
      @gig = Lml::Gig.new(start_time: Time.now)
    end
  end
end
