# frozen_string_literal: true

module Backstage
  module Search
    class VenuesController < Backstage::ApplicationController
      def index
        q = params[:q].to_s.strip
        venues = Lml::Venue.all
        venues = venues.where("LOWER(name) LIKE LOWER(?)", "%#{q}%") if q.present?
        venues = venues.order(:name).limit(10)

        render json: venues.map { |v| { id: v.id, label: "#{v.name} (#{v.location})" } }
      end
    end
  end
end
