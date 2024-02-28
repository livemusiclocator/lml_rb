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
      f.input :date
      f.input :status
      f.input :start_time
      f.input :finish_time
    end
    f.actions
  end
end
