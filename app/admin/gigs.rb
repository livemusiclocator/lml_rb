ActiveAdmin.register Lml::Gig, as: "Gig" do
  permit_params(
    :date,
    :status_id,
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
      f.input :venue
      f.input :headline_act
      f.input :date, as: :date_picker
      f.input :status
      f.input :start_time, as: :datetime_picker
      f.input :finish_time, as: :datetime_picker
    end
    f.actions
  end

  controller do
    def new
      @gig = Lml::Gig.new(start_time: Time.now)
    end
  end
end
