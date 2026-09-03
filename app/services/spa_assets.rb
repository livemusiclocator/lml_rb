# frozen_string_literal: true

require "net/http"
require "json"

# Where the gig explorer's built assets are right now.
#
# config/spa_assets.yml holds the last known answer: rake spa:fetch writes it and
# the initializer reads it at boot. On its own that is only ever as fresh as the
# last rails deploy, so a frontend release stayed invisible here until someone
# reran the task and shipped the yaml.
#
# The frontend publishes a manifest.json beside every bundle it deploys, so ask
# it instead - at most once a REFRESH_AFTER per process. Every failure falls back
# to what we already had, ultimately the checked in yaml, so a slow, broken or
# unreachable manifest can only ever leave the page as it is today. It can never
# take one down.
class SpaAssets
  REFRESH_AFTER = 1.minute
  OPEN_TIMEOUT = 2
  READ_TIMEOUT = 2

  MUTEX = Mutex.new

  class << self
    def current
      refresh if refresh_due?
      @fetched || configured
    end

    # for specs, and for a console watching a deploy land
    def reset!
      MUTEX.synchronize do
        @fetched = nil
        @fetched_at = nil
      end
    end

    private

    def configured
      Rails.application.config.spa_assets
    end

    def refresh_due?
      return false unless enabled?

      @fetched_at.nil? || @fetched_at < REFRESH_AFTER.ago
    end

    # the manifest sits beside the bundle, so there is nothing to ask when no
    # bundle is configured, and nothing worth asking in specs
    def enabled?
      configured["entrypoint_script"].present? && !Rails.env.test?
    end

    def refresh
      MUTEX.synchronize do
        # another thread may have refreshed while this one waited for the lock
        return unless refresh_due?

        # stamped before the fetch, so a manifest that is down is asked once a
        # minute like any other rather than on every single request
        @fetched_at = Time.current
        assets = fetch_manifest
        @fetched = assets if assets
      end
    end

    def fetch_manifest
      base_url = configured["entrypoint_script"].sub(%r{/[^/]+\z}, "")
      response = get("#{base_url}/manifest.json")
      return nil unless response.is_a?(Net::HTTPSuccess)

      build_assets(JSON.parse(response.body), base_url)
    rescue StandardError => e
      # the page renders from the last good answer, so this is a warning and not
      # something to raise in front of a visitor
      Rails.logger.warn("SpaAssets could not read the manifest: #{e.class}: #{e.message}")
      nil
    end

    # the same shape rake spa:fetch writes, so the runtime answer and the checked
    # in one cannot drift apart
    def build_assets(manifest, base_url)
      entry = manifest["index.html"]
      return nil if entry.blank? || entry["file"].blank?

      {
        "entrypoint_script" => "#{base_url}/#{entry["file"]}",
        "css_files" => Array(entry["css"]).map { |file| "#{base_url}/#{file}" },
        "external_dependencies" => external_dependencies(manifest, base_url),
      }
    end

    def external_dependencies(manifest, base_url)
      manifest.values
              .select { |item| item["isEntry"] && item["file"].to_s.end_with?("js") && item["src"] != "index.html" }
              .map { |item| "#{base_url}/#{item["file"]}" }
    end

    def get(url)
      uri = URI(url)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT,
      ) { |http| http.get(uri.request_uri) }
    end
  end
end
