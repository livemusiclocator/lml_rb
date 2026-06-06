# frozen_string_literal: true

module Backstage
  module Search
    class GigsController < Backstage::ApplicationController
      def index
        q = params[:q].to_s.strip
        gigs = Lml::Gig.visible.joins(:venue)
        gigs = gigs.where(venue_id: params[:venue_id]) if params[:venue_id].present?
        gigs = gigs.where("LOWER(gigs.name) LIKE LOWER(?)", "%#{q}%") if q.present?
        gigs = gigs.order(:date, :name).limit(10)

        render json: gigs.map { |g| { id: g.id, label: g.display_name } }
      end
    end
  end
end
