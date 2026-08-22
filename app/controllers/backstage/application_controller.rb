# frozen_string_literal: true

module Backstage
  class ApplicationController < ::ApplicationController
    before_action :authenticate_user!
    layout "backstage"

    def current_user_manages?(resource)
      case resource
      when Lml::Venue then current_user.manages_venue?(resource)
      when Lml::Act then current_user.manages_act?(resource)
      else false
      end
    end
    helper_method :current_user_manages?

    private

    # Not a global before_action - most of backstage is for punters. Pages that
    # carry admin authority opt in.
    def require_admin!
      redirect_to backstage_root_path, alert: "That area is for admins." unless current_user.admin?
    end
  end
end
