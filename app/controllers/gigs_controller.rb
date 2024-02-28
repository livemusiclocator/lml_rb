class GigsController < ApplicationController
  def query
    content = []

    Lml::Gig.all.each do |gig|
      venue = gig.venue
      headline_act = gig.headline_act
      current = {
        id: gig.id,
        name: gig.name,
        start_time: gig.start_time,
        finish_time: gig.finish_time,
        venue: {
          id: venue.id,
          name: venue.name,
          address: venue.address,
          latitude: venue.latitude,
          longitude: venue.longitude,
        },
        headline_act: {
          id: headline_act.id,
          name: headline_act.name,
          genres: headline_act.genres,
        },
        sets: [],
      }
      gig.sets.each do |set|
        act = set.act
        current[:sets] << {
          act: {
            id: act.id,
            name: act.name,
            genres: act.genres,
          },
          start_time: set.start_time,
        }
      end
      content << current
    end

    render json: content
  end
end
