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
          date_to: Date.today.advance(days: 7),
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

  def for
    expires_in 1.minutes, public: true

    location = params[:location] || "nowhere"
    date = Date.parse(params[:date] || "2000-01-01")

    venue_ids = Lml::Venue.where("lower(location) = ?", location).pluck(:id)

    @gigs = Lml::Gig.eager.visible.where(date: date, venue_id: venue_ids)

    render :query
  end

  def query
    expires_in 1.minutes, public: true

    location = params[:location] || "nowhere"
    date_from = Date.parse(params[:date_from] || "2000-01-01")
    date_to = Date.parse(params[:date_to] || "2000-01-01")

    date_to = date_from + 7.days if !tokens.include?(params[:token]) && (date_to > date_from + 7.days)

    venue_ids = Lml::Venue.where("lower(location) = ?", location).pluck(:id)

    @gigs = Lml::Gig.eager.visible.where(date: (date_from..date_to), venue_id: venue_ids)
  end

  def show
    @gig = Lml::Gig.find(params[:id])
  end

  def autocomplete
    @gigs = Lml::Gig.order(:name)
  end

  def feed
    @gigs = Lml::Gig.order("date DESC").limit(Rails.configuration.rss_items)

    respond_to do |format|
      format.rss { render :layout => false }
    end
  end

  private

  def tokens
    return [] unless ENV["TOKENS"]

    ENV.fetch("TOKENS").split(",").map(&:strip)
  end
end
