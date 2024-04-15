# frozen_string_literal: true

class GigsController < ApplicationController
  def index
    @links = [
      {
        id: "_self",
        href: url_for(
          action: :index,
          format: request.params[:format],
        ),
      },
      {
        id: "default",
        href: url_for(
          action: :query,
          format: request.params[:format],
        ),
      },
      {
        id: "today",
        href: url_for(
          action: :query,
          format: request.params[:format],
          location: "castlemaine",
          date_from: Date.today,
          date_to: Date.today,
        ),
      },
      {
        id: "next_seven_days",
        href: url_for(
          action: :query,
          format: request.params[:format],
          location: "castlemaine",
          date_from: Date.today,
          date_to: Date.today.advance(days:7),
        ),
      },
      {
        id: "this_weekend",
        href: url_for(
          action: :query,
          format: request.params[:format],
          location: "castlemaine",
          date_from: Date.today.end_of_week.advance(days: -2),
          date_to: Date.today.end_of_week,
        ),
      },
      {
        id: "next_weekend",
        href: url_for(
          action: :query,
          format: request.params[:format],
          location: "castlemaine",
          date_from: Date.today.next_week.end_of_week.advance(days: -2),
          date_to: Date.today.next_week.end_of_week,
        ),
      },
      # TODO: technically supposed to supply this as {?date} but that gets escaped so...
      {
        id: "on_date",
        templated: true,
        href: url_for(
          action: :query,
          format: request.params[:format],
          location: "castlemaine",
          date_from: "date",
          date_to: "date",
        ),
      },
    ]
  end

  INCLUDE_LOCATIONS = {
    "melbourne" => %w[vic victoria],
    "brisbane" => %w[qld queensland],
    "sydney" => %w[nsw],
    "adelaide" => %w[sa],
    "lbmf" => %w[melbourne vic victoria],
  }.freeze

  def query
    location = params[:location] || "nowhere"
    locations = [location] + (INCLUDE_LOCATIONS[location.downcase] || [])

    date_from = params[:date_from]
    date_to = params[:date_to]

    venue_ids = Lml::Venue.where("lower(location) in (?)", locations).pluck(:id)

    gigs_relation = Lml::Gig.eager.status_confirmed

    gigs_relation = gigs_relation.where("tags @> ?", %w[lbmf].to_json) if location == "lbmf"

    @gigs = gigs_relation.where(date: (date_from..date_to), venue_id: venue_ids)
  end

  def autocomplete
    @gigs = Lml::Gig.order(:name)
  end
end
