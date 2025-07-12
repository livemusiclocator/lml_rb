require 'open-uri'
require 'json'
namespace :spa do
  def self.fetch_url(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    request = Net::HTTP::Get.new(uri.request_uri)

    http.request(request)
  end
  desc "Fetch SPA build from Firebase and generate manifest helper and update the checked in configuration file"
  task :fetch do
    base_url = ENV['SPA_BASE_URL'] || 'https://assets.livemusiclocator.com.au/rails_spa'
    manifest_url = "#{base_url}/manifest.json"
    manifest_response = fetch_url(manifest_url)
    manifest = JSON.parse(manifest_response.body)
    # Just register the URLs - don't download anything

    entry = manifest['index.html']

    spa_config = {
      'spa.js' => "#{base_url}/#{entry['file']}",
      'spa.css' => entry['css']&.first ? "#{base_url}/#{entry['css'].first}" : nil
    }.compact

    File.open('config/spa_assets.yml', 'w') do |config_file|
      config_file.write("# Please run rake spa:fetch to update this file\n")
      config_file.write({ production: spa_config, development: spa_config, test: spa_config }.deep_stringify_keys.to_yaml)
    end
  end
end
