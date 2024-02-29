ActiveAdmin.register Lml::Set, as: "Set" do
  permit_params :event_id, :artist_id, :start_time, :finish_time

  filter :none

  form do |f|
    f.inputs do
      f.input :gig
      f.input :act
      f.input :start_time, as: :datetime_picker
      f.input :finish_time, as: :datetime_picker
    end
    f.actions
  end

  controller do
    def new
      @set = Lml::Set.new(start_time: Time.now, finish_time: Time.now)
    end
  end
end
