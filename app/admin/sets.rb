ActiveAdmin.register Lml::Set, as: "Set" do
  permit_params :event_id, :artist_id, :start_time, :finish_time

  filter :none

  form do |f|
    f.inputs do
      f.input :event
      f.input :artist
      f.input :start_time
      f.input :finish_time
    end
    f.actions
  end
end
