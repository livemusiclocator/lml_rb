# frozen_string_literal: true

module Backstage
  # Where an admin issues and revokes their own admin API tokens. Nobody sees or
  # touches anybody else's - every query here is scoped to current_user.
  class ApiTokensController < ApplicationController
    before_action :require_admin!

    EXPIRY_CHOICES = { "30" => 30, "90" => 90, "365" => 365 }.freeze

    def index
      load_tokens
    end

    def create
      @issued = Lml::ApiToken.issue!(user: current_user, name: token_name, expires_at: expires_at)
      # Rendered rather than redirected on purpose: the secret is shown once,
      # from this response, and never goes near the flash or a cookie.
      load_tokens
      render :index
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Could not issue that token: #{e.record.errors.full_messages.to_sentence}"
      load_tokens
      render :index, status: :unprocessable_content
    end

    def destroy
      tokens.find(params[:id]).revoke!
      redirect_to backstage_api_tokens_path, notice: "Token revoked. Anything using it stops working now."
    end

    private

    def load_tokens
      @tokens = tokens.order(created_at: :desc)
    end

    def tokens
      current_user.api_tokens
    end

    def token_name
      params[:name].to_s.strip
    end

    def expires_at
      EXPIRY_CHOICES[params[:expires_in_days].to_s]&.days&.from_now
    end
  end
end
