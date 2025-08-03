require 'open-uri'
require 'json'
namespace :spa do
  def self.fetch_url(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    puts(uri)
    request = Net::HTTP::Get.new(uri.request_uri)

    http.request(request)
  end
  desc "Fetch SPA build from Firebase and generate manifest helper and update the checked in configuration file"
  task :fetch do
    def per_install_fetch install, allow_override=false
        base_url = (allow_override and ENV['SPA_BASE_URL']) ? ENV['SPA_BASE_URL'] : "https://assets.livemusiclocator.com.au/lml_gig_explorer_#{install}"
        manifest_url = "#{base_url}/manifest.json"
        manifest_response = fetch_url(manifest_url)
        manifest = JSON.parse(manifest_response.body)
        # Just register the URLs - don't download anything

        entry = manifest['index.html']
        # grab entrypoints that are js from manifest
        external_dependencies = manifest.values.filter{|item| item['isEntry'] && item["file"].end_with?("js") && item["src"]!="index.html" }.map { |item| item["file"] }
        {
          'entrypoint_script' => "#{base_url}/#{entry['file']}",
          'css_files' => entry['css'].map { |file| "#{base_url}/#{file}"},
          'external_dependencies' => external_dependencies.map { |file| "#{base_url}/#{file}"},
        }.compact

    end

    all_configs = {
      # switch to www install when we go live (because cors headers are different - there was probably a better way!)
      production: per_install_fetch("live"),
      test: per_install_fetch("beta"),
      development: per_install_fetch("dev",true)
    }
    File.open('config/spa_assets.yml', 'w') do |config_file|
      config_file.write("# Please run rake spa:fetch to update this file\n")
      config_file.write(all_configs.deep_stringify_keys.to_yaml)
    end
  end
end
