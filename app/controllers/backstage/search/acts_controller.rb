# frozen_string_literal: true

module Backstage
  module Search
    class ActsController < Backstage::ApplicationController
      def index
        q = params[:q].to_s.strip
        acts = Lml::Act.all
        acts = acts.where("LOWER(name) LIKE LOWER(?)", "%#{q}%") if q.present?
        acts = acts.order(:name).limit(10)

        render json: acts.map { |a| { id: a.id, label: a.name } }
      end
    end
  end
end
