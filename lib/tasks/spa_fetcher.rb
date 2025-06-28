# lib/spa_fetcher.rb
require 'open-uri'
require 'json'

module Tasks
  class SpaFetcher
    def self.fetch

    puts "Fetching SPA manifest from Firebase..."

    firebase_base = ENV['SPA_BASE_URL'] || 'https://lml-seo.web.app/rails_spa' # temp endpoint name - probably needs to be configd

    manifest_url = "#{firebase_base}/manifest.json"
    manifest_response = fetch_url(manifest_url)
    manifest = JSON.parse(manifest_response.body)

    # Just register the URLs - don't download anything
    register_spa_assets(firebase_base, manifest)

    puts "✅ SPA assets registered with Rails"
    end

  private

  def self.register_spa_assets(base_url, manifest)
    entry = manifest['index.html']

    spa_config = {
      'spa.js' => "#{base_url}/#{entry['file']}",
      'spa.css' => entry['css']&.first ? "#{base_url}/#{entry['css'].first}" : nil
    }.compact

    Rails.application.config.spa_assets = spa_config

    puts "Registered SPA assets:"
    spa_config.each do |key, url|
      puts "  #{key} -> #{url}"
    end
  end

  def self.fetch_url(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.read_timeout = 30
    http.open_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Rails-Asset-Fetcher/1.0'

    http.request(request)
  end
  end
end
