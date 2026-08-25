# frozen_string_literal: true

class ActsController < ApplicationController
  include PickerResults

  # Only the ActiveAdmin forms on this subdomain use this, and the admin session
  # cookie is already there. It is not part of the public API.
  before_action :authenticate_admin_user!

  # The gig form's set list picker needs two things the pair does not carry: the
  # act as a set line names it, and the genres to copy onto the gig. Both ride
  # along here rather than costing a second round trip; other pickers ignore them.
  def search
    render_picker_results(Lml::Act.search(params[:q])) do |act|
      { set_list_name: act.set_list_name, genres: act.genres || [] }
    end
  end
end
