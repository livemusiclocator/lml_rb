ActiveAdmin.register Lml::Gig, as: "Gig" do
  permit_params(
    :date,
    :event_status_id,
    :finish_time,
    :headline_artist_id,
    :name,
    :start_time,
    :venue_id,
  )

  filter :none

  form do |f|
    f.inputs do
      f.input :name
      f.input :venue
      f.input :headline_artist
      f.input :date
      f.input :event_status
      f.input :start_time
      f.input :finish_time
    end
    f.actions
  end
end
