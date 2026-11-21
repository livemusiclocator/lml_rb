# frozen_string_literal: true

module Web
  module AnalyticsHelper
    PROD_GA_MEASUREMENT_ID = "G-8TKSCK99CN"
    DEV_GA_MEASUREMENT_ID  = "G-Y3W30VYBWV"
    GTAG_SNIPPET = <<~HTML
            <!-- Google tag (gtag.js) -->
            <script async src="https://www.googletagmanager.com/gtag/js?id=%<tag_id>s"></script>
            <script>
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('js', new Date());
      %<debug_set>s        gtag('config', '%<tag_id>s'%<config>s);
            </script>
    HTML

    def analytics_enabled?
      return false if Rails.env.test?
      return true if Rails.env.production?

      ActiveModel::Type::Boolean.new.cast(ENV.fetch("ENABLE_ANALYTICS", nil)) == true
    end

    def google_analytics_tag(measurement_id = nil)
      return unless analytics_enabled?

      measurement_id ||= default_measurement_id
      return if measurement_id.blank?

      gtag_script_tag(ERB::Util.html_escape(measurement_id), debug_mode: Rails.env.development?)
    end

    private

    def default_measurement_id
      fallback = Rails.env.production? ? PROD_GA_MEASUREMENT_ID : DEV_GA_MEASUREMENT_ID
      ENV.fetch("GA_MEASUREMENT_ID", nil).presence || fallback
    end

    def gtag_script_tag(tag_id, debug_mode: false)
      config = debug_mode ? ", { debug_mode: true }" : ""
      debug_set = debug_mode ? "        gtag('set', { debug_mode: true });\n" : ""
      format(GTAG_SNIPPET, tag_id: tag_id, config: config, debug_set: debug_set).html_safe
    end
  end
end
