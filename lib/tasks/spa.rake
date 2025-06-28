require 'open-uri'
require 'json'
require_relative './spa_fetcher'

namespace :spa do
  desc "Fetch SPA build from Firebase and generate manifest helper"
  task :fetch do
    Tasks::SpaFetcher.fetch()
  end
end

Rake::Task['assets:precompile'].enhance(['spa:fetch'])


