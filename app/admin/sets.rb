ActiveAdmin.register Lml::Set, as: "Set" do
  permit_params :gig_id, :act_id, :start_time, :finish_time

  filter :none

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
      @set = Lml::Set.new(start_time: Time.now, finish_time: Time.now)
    end
  end
end
