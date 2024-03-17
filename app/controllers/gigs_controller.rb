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
          date_from: Date.today,
          date_to: Date.today,
        ),
      },
      {
        id: "next_seven_days",
        href: url_for(
          action: :query,
          format: request.params[:format],
          date_from: Date.today,
          date_to: Date.today.advance(days:7),
        ),
      },
      {
        id: "this_weekend",
        href: url_for(
          action: :query,
          format: request.params[:format],
          date_from: Date.today.end_of_week.advance(days: -2),
          date_to: Date.today.end_of_week,
        ),
      },
      {
        id: "next_weekend",
        href: url_for(
          action: :query,
          format: request.params[:format],
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
          date_from: "date",
          date_to: "date",
        ),
      },
    ]
  end

  def query
    date_from = params[:date_from]
    date_to = params[:date_to]
    @gigs = if date_from && date_to
              Lml::Gig.eager.status_confirmed.filter_by_date((date_from..date_to))
            else
              # TODO: move time based filtering to the client?
              Lml::Gig.eager.status_confirmed.upcoming
            end
  end

  def autocomplete
    @gigs = Lml::Gig.order(:name)
  end
end
