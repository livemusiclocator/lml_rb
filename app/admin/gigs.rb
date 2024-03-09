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

  form do |f|
    f.inputs do
      f.input :name
      f.input :venue_name
      f.input :venue_id, as: "hidden"
      f.input :headline_act_name
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
