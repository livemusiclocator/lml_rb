# frozen_string_literal: true

module Backstage
  class SessionsController < Devise::SessionsController
    layout "backstage"

    def after_sign_in_path_for(_resource)
      backstage_root_path
    end

    def after_sign_out_path_for(_resource)
      new_user_session_path
    end
  end
end
