# frozen_string_literal: true

module Lml
  module Processors
    class VenueCsv
      def initialize(upload)
        @upload = upload
      end

      def process!
        CSV.parse(@upload.content, headers: true) do |row|
          name = row["name"].strip

          venue = Lml::Venue.where("lower(name) = ?", name.downcase).first
          venue ||= Lml::Venue.create(name: name)
          venue.website = row["website"]
          venue.capacity = row["capacity"]
          venue.address = [
            row["street_address"],
            row["suburb"],
          ].join(" ")
          venue.postcode = row["postcode"]
          venue.latitude = row["latitude"]
          venue.longitude = row["longitude"]
          venue.location = row["location"]
          venue.time_zone = case row["postcode"]
                            when /^0/
                              "Darwin"
                            when /^2/
                              "Sydney"
                            when /^3/
                              "Melbourne"
                            when /^4/
                              "Brisbane"
                            when /^5/
                              "Adelaide"
                            when /^6/
                              "Perth"
                            when /^6/
                              "Hobart"
                            end
          venue.save
        end
      end
    end
  end
end
