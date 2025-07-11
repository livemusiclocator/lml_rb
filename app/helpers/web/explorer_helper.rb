# frozen_string_literal: true

module Web
  module ExplorerHelper
    DEFAULT_APP_CONFIG = {
      render_app_layout: false,
      allow_select_location: true,
      default_location: "anywhere",
    }.freeze

    EDITION_SPECIFIC_CONFIG = {
      "stkilda" => {
        default_location: "stkilda",
        allow_select_location: false,
      },
    }.freeze

    def frontend_app_config
      config = DEFAULT_APP_CONFIG.merge(EDITION_SPECIFIC_CONFIG[params[:edition_id]] || {})

      # TODO: restore this when working ok on subdomain or figure a better way to do this
      config.merge({ gigs_endpoint: web_api_root_path },
                   root_path: relative_path({ path_name: :web_root }),).to_json
    end

    def spa_javascript_tag
      return unless Rails.application.config.spa_assets["spa.js"]

      javascript_include_tag(
        Rails.application.config.spa_assets["spa.js"],
        type: "module",
        "data-turbo-track": "reload",
      )
    end

    def spa_stylesheet_tag
      return unless Rails.application.config.spa_assets["spa.css"]

      stylesheet_link_tag(
        Rails.application.config.spa_assets["spa.css"],
        "data-turbo-track": "reload",
      )
    end

    def spa_preload_tags
      tags = []

      if Rails.application.config.spa_assets["spa.js"]
        tags << preload_link_tag(
          Rails.application.config.spa_assets["spa.js"],
          as: :script,
        )
      end

      if Rails.application.config.spa_assets["spa.css"]
        tags << preload_link_tag(
          Rails.application.config.spa_assets["spa.css"],
          as: :style,
        )
      end

      safe_join(tags)
    end
  end
end
