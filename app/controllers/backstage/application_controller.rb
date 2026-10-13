# frozen_string_literal: true

module Backstage
  class ApplicationController < ::ApplicationController
    before_action :authenticate_user!
    layout "backstage"

    # Admins carry every manager's authority, so their changes skip review too.
    def current_user_manages?(resource)
      return true if current_user.admin?

      case resource
      when Lml::Venue then current_user.manages_venue?(resource)
      when Lml::Act then current_user.manages_act?(resource)
      when Lml::Gig then resource.venue.present? && current_user.manages_venue?(resource.venue)
      else false
      end
    end
    helper_method :current_user_manages?

    # An admin can reach every venue; anybody else only the ones they manage.
    def accessible_venues
      current_user.admin? ? Lml::Venue.all : current_user.managed_venues
    end

    private

    # Not a global before_action - most of backstage is for punters. Pages that
    # carry admin authority opt in.
    def require_admin!
      redirect_to backstage_root_path, alert: "That area is for admins." unless current_user.admin?
    end
  end
end
