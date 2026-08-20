# frozen_string_literal: true

class VenuesController < ApplicationController
  include PickerResults
  include TokenAccess

  # See ActsController - admin picker only, not public API.
  before_action :authenticate_admin_user!, only: :search
  before_action :authorize_token!, only: :autocomplete

  # Temporarily reinstated. This was withdrawn with the other autocomplete
  # endpoints because it let anyone enumerate every venue, but an internal
  # caller had already built against it, so it is back behind a TOKENS shared
  # secret until they can move to /venues/search or a purpose built feed.
  def autocomplete
    render json: Lml::Venue.order(:name).map { |venue| { id: venue.id, label: venue.label } }
  end

  def search
    render_picker_results(Lml::Venue.search(params[:q]))
  end
end
