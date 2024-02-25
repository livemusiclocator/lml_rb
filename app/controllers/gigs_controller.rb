class GigsController < ApplicationController
  def query
    content = []

    Event.all.each do |event|
      content << {
        name: event.name,
        start_time: event.start_time,
        finish_time: event.finish_time,
      }
    end

    render json: content
  end
end
