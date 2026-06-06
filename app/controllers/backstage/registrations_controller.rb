# frozen_string_literal: true

module Backstage
  class RegistrationsController < Devise::RegistrationsController
    layout "backstage"

    def after_sign_up_path_for(_resource)
      backstage_root_path
    end

    private

    def sign_up_params
      params.require(:user).permit(:email, :display_name, :password, :password_confirmation)
    end
  end
end
