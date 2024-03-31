# frozen_string_literal: true

namespace :scrape do
  desc "rescrape all uploads"
  task all: :environment do
    FetchEventfindaJob.perform_now
    Lml::Upload.find_each do |upload|
      puts "Rescraping #{upload.source}"
      upload.rescrape!
    end
  end
end
