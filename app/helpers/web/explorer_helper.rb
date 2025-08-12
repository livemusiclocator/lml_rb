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
        # use this durig dev to randomly assign series to gigs if needed
        # only works with dev build of frontend
        # shuffleSeriesAssignments: ["stkildafestival2025", "nope", "nope", "nope"],
        themes: {
          series: {
            stkildafestival2025: {
              searchResult: "gigSeriesCustom/skf_blacklogo.svg",
              savedMapPin: "mapPins/festival-pin-saved.png",
              defaultMapPin: "mapPins/festival-pin.png",
            },
          },
        },
      },
      "geelong" => {
        default_location: "geelong",
        allow_select_location: false,
      },
    }.freeze

    def frontend_app_config
      config = DEFAULT_APP_CONFIG.merge(EDITION_SPECIFIC_CONFIG[params[:edition_id]] || {})

      # TODO: restore this when working ok on subdomain or figure a better way to do this
      config.merge({ gigs_endpoint: web_api_root_url },
                   root_path: relative_path({ path_name: :web_root }),).to_json
    end

    def spa_entrypoint_javascript_tag
      return unless Rails.application.config.spa_assets["entrypoint_script"]

      javascript_include_tag(
        Rails.application.config.spa_assets["entrypoint_script"],
        type: "module",
        preload: true,
        crossorigin: "anonymous",
        "data-turbo-track": "reload",
      )
    end

    def spa_stylesheet_tags
      return unless Rails.application.config.spa_assets["css_files"]

      tags = Rails.application.config.spa_assets["css_files"].map do |css_file|
        stylesheet_link_tag(
          css_file,
          preload: true,
          crossorigin: "anonymous",
          "data-turbo-track": "reload",
        )
      end
      safe_join(tags)
    end

    def spa_external_dependency_tags
      return unless Rails.application.config.spa_assets["external_dependencies"]

      tags = Rails.application.config.spa_assets["external_dependencies"].map do |asset_path|
        javascript_include_tag(
          asset_path,
          preload: true,
          crossorigin: "anonymous",
          "data-turbo-track": "reload",
        )
      end

      safe_join(tags)
    end

    def spa_preload_tags
      # TODO: preloading more css than we probably want to - do we want to or need to preload the leaflet stuff? it
      # will not result in flash of unstyled etc. as much as the main css and the fonts will?
      spa_assets = Rails.application.config.spa_assets
      preloadable_asset_paths = [spa_assets["entrypoint"]] + (spa_assets["css_files"] || [])
      tags = preloadable_asset_paths.compact.map do |asset_path|
        link_type = asset_path.end_with?("js") ? :script : :style
        rel = asset_path.end_with?("js") ? :modulepreload : :preload
        preload_link_tag(asset_path, as: link_type, rel: rel, crossorigin: "anonymous")
      end

      safe_join(tags)
    end
  end
end
