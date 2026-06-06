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
  end
end
