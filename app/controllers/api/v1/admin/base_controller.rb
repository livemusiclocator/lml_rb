# frozen_string_literal: true

module Api
  module V1
    module Admin
      # The admin write API's single gate.
      #
      # ActionController::API rather than ::ApplicationController on purpose:
      # nothing here can authenticate from a cookie, so nothing here can be
      # driven by a browser carrying somebody's session. That is the whole CSRF
      # story for these endpoints - there is no ambient credential to forge with.
      #
      # Bearer tokens only, never a query parameter: query strings end up in
      # router logs, referrers and shell history, which is exactly how the
      # TOKENS shared secret leaks (see TokenAccess).
      class BaseController < ActionController::API
        BEARER = /\ABearer\s+(?<secret>\S+)\z/
        DEFAULT_PER_PAGE = 50
        MAX_PER_PAGE = 100

        before_action :authenticate_api_token!
        before_action :require_admin!

        # Best effort only - the cache store is per dyno, and guessing a 256 bit
        # secret is not the threat. This is here to stop a runaway integration
        # from taking the database down with it.
        rate_limit to: 300, within: 1.minute,
                   by: -> { current_api_token.id },
                   with: -> { render_error(:too_many_requests, "Slow down - 300 requests a minute.") }

        rescue_from ActiveRecord::RecordNotFound, with: :not_found
        rescue_from ActionController::ParameterMissing, with: :parameter_missing

        private

        attr_reader :current_api_token

        def authenticate_api_token!
          @current_api_token = Lml::ApiToken.authenticate(presented_secret)
          return unauthorized unless @current_api_token

          @current_api_token.record_use!
        end

        # A token only says who is calling. Whether they still have any authority
        # is asked again on every request, so demoting an admin takes effect
        # immediately even if a token of theirs survives.
        def require_admin!
          forbidden unless current_admin&.admin?
        end

        def current_admin
          current_api_token&.user
        end

        def presented_secret
          BEARER.match(request.authorization.to_s)&.[](:secret)
        end

        def unauthorized
          response.set_header("WWW-Authenticate", "Bearer realm=\"lml admin api\"")
          render_error(:unauthorized, "Provide an admin API token as `Authorization: Bearer <token>`.")
        end

        def forbidden
          render_error(:forbidden, "That token's owner is not an admin.")
        end

        def not_found
          render_error(:not_found, "No such record.")
        end

        def parameter_missing(error)
          render_error(:bad_request, "Missing parameter: #{error.param}.")
        end

        def render_error(status, message, details: nil)
          body = { error: message }
          body[:details] = details if details
          render json: body, status: status
        end

        def render_invalid(record)
          render_error(:unprocessable_content, "That record is not valid.", details: record.errors.to_hash)
        end

        # Every collection is paginated. An admin token that can dump a whole
        # table in one request is a much bigger thing to lose than one that cannot.
        def paginate(scope)
          scope.limit(per_page).offset((page - 1) * per_page)
        end

        def pagination_meta(scope)
          { page: page, per_page: per_page, total: scope.count }
        end

        def page
          [params[:page].to_i, 1].max
        end

        def per_page
          requested = params[:per_page].to_i
          return DEFAULT_PER_PAGE if requested < 1

          [requested, MAX_PER_PAGE].min
        end
      end
    end
  end
end
