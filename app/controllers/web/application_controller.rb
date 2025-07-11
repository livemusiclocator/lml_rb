class Web::ApplicationController < ApplicationController
  layout 'web/layouts/application'
  rescue_from ActiveRecord::RecordNotFound, with: :render_custom_not_found

  private

  def render_custom_not_found
    render 'web/shared/404', status: :not_found, layout: false
  end
end
