# frozen_string_literal: true

class ActsController < ApplicationController
  include PickerResults

  # Only the ActiveAdmin forms on this subdomain use this, and the admin session
  # cookie is already there. It is not part of the public API.
  before_action :authenticate_admin_user!

  def search
    render_picker_results(Lml::Act.search(params[:q]))
  end
end
