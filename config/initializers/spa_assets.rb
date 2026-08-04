Rails.application.configure do
  config.spa_assets = config_for(:spa_assets)

  # Point a local rails at a locally built frontend client instead of the dev
  # bundle deployed to firebase, without rewriting the checked in config:
  #
  #   lml_frontend_client$ make watch
  #   lml_rb$ SPA_BASE_URL=https://assets.lml.test/lml_gig_explorer_dev bin/rails server
  #
  # The file names are fixed by the frontend's rollup config, so unlike
  # rake spa:fetch there is no manifest to read.
  if Rails.env.development? && ENV["SPA_BASE_URL"].present?
    base_url = ENV["SPA_BASE_URL"].chomp("/")
    config.spa_assets = {
      "entrypoint_script" => "#{base_url}/lml_gig_explorer.js",
      "css_files" => ["#{base_url}/lml_gig_explorer.css"],
      "external_dependencies" => [],
    }
  end
end
