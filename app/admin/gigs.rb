ActiveAdmin.register Lml::Gig, as: "Gig" do
  permit_params(
    :date,
    :status,
    :finish_time,
    :headline_act_id,
    :ticketing_url,
    :tag_list,
    :name,
    :start_time,
    :venue_id,
  )

  filter :name_cont, label: "Name"

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
      row :ticketing_url
      row :tag_list
      row :headline_act
      row :created_at
      row :updated_at
    end

    panel "Sets" do
      table_for gig.sets do
        column :id do |set|
          link_to set.id, admin_set_path(set)
        end
        column :act
        column :start_time
        column :finish_time
      end
    end
  end

  action_item :add_set, only: %i[show] do
    link_to "Add Set", new_admin_set_path(gig_id: gig.id, start_time: gig.start_time, end_time: gig.finish_time), method: :get
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input :headline_act_label, label: "Headline Act"
      f.input :headline_act_id, as: "hidden"
      f.input :date, as: :date_picker
      f.input :ticketing_url
      f.input :tag_list
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
end
