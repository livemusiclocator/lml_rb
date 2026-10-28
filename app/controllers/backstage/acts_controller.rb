# frozen_string_literal: true

module Backstage
  # Every act, for admins - the backstage counterpart of ActiveAdmin's acts.
  # Act managers still change their own acts through proposals.
  class ActsController < ApplicationController
    LIMIT = 50
    # What ActiveAdmin's act form edits.
    EDITABLE_ATTRIBUTES = %i[
      name
      location
      country
      genre_list
      alias_list
      email
      website
      instagram
      facebook
      linktree
      bandcamp
      spotify
      youtube
      musicbrainz
      rym
      wikipedia
    ].freeze

    before_action :require_admin!

    def index
      @query = params[:q].to_s.strip
      acts = Lml::Act.search(@query)
      @act_count = acts.count
      @acts = acts.limit(LIMIT)
    end

    def new
      @act = Lml::Act.new(country: "Australia")
    end

    def create
      @act = Lml::Act.new(act_params)

      if save_act(@act)
        redirect_to backstage_acts_path(q: @act.name), notice: "Added #{@act.name}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @act = Lml::Act.find(params[:id])
    end

    def update
      @act = Lml::Act.find(params[:id])
      @act.assign_attributes(act_params)

      if save_act(@act)
        redirect_to backstage_acts_path(q: @act.name), notice: "Saved #{@act.name}."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def act_params
      params.require(:act).permit(*EDITABLE_ATTRIBUTES)
    end

    # Set lists create acts with next to nothing, so the model does not insist
    # on a name. Somebody typing one in by hand has no excuse.
    def save_act(act)
      act.validate
      act.errors.add(:name, :blank) if act.name.blank?
      act.errors.empty? && act.save
    end
  end
end
