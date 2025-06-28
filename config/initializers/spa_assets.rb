# Initialize empty SPA assets config
Rails.application.configure do
  config.spa_assets = {}
end


if Rails.env.development?
  Rails.application.config.after_initialize do
    # Force run the spa:fetch task on Rails startup
    if Rails.application.config.spa_assets.blank?
      puts "Fetching SPA manifest for development..."
      begin
        # Directly call the task logic instead of invoke
        require "tasks/spa_fetcher"
        Tasks::SpaFetcher.fetch()
      rescue => e
        puts "Warning: Could not fetch SPA manifest - #{e.message}"
      end
    end
  end
end
