ActiveAdmin.register Event do
  permit_params :name, :venue_id, :headline_artist_id, :date, :start_time, :finish_time

  filter :none

  form do |f|
    f.inputs do
      f.input :name
      f.input :venue
      f.input :headline_artist
      f.input :date
      f.input :start_time
      f.input :finish_time
    end
    f.actions
  end
end
