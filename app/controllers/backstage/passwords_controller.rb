# frozen_string_literal: true

module Backstage
  class PasswordsController < Devise::PasswordsController
    layout "backstage"
  end
end
