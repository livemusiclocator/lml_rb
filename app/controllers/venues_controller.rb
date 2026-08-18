# frozen_string_literal: true

class VenuesController < ApplicationController
  include PickerResults

  # See ActsController - admin picker only, not public API.
  before_action :authenticate_admin_user!

  def search
    render_picker_results(Lml::Venue.search(params[:q]))
  end
end
