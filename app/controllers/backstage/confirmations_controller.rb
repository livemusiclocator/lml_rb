# frozen_string_literal: true

module Backstage
  class ConfirmationsController < Devise::ConfirmationsController
    layout "backstage"
  end
end
