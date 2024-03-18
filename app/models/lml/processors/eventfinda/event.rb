#!/usr/bin/env ruby
module Lml
  module Processors
    module Eventfinda
      # Todo: do these live in schemaorg-specific code (or use gem)
      CONTEXT="https://schema.org"
      EVENT_STATUS = {
        cancelled: "#{CONTEXT}/EventCancelled",
        scheduled: "#{CONTEXT}/EventScheduled"
                     }
      class Image
        include ActiveModel::Model
        attr_accessor :original_url, :is_primary, :id, :transforms
      end
      class Point
        include ActiveModel::Model
        attr_accessor :lat, :lng
        def to_schema_org_builder
          Jbuilder.new do |geo|
            geo.set! "@type", :GeoCoordinates
            geo.latitude lat
            geo.longitude lng
          end
        end
      end
      class Location
        include ActiveModel::Model
        attr_accessor :count_current_events, :description, :id, :images, :is_venue, :name, :point, :summary , :url_slug
        def initialize raw
          super(raw)
          @point = Point.new(raw[:point])
        end
        def to_schema_org_builder
          Jbuilder.new do |location|
            location.set! "@type", :Place
            location.name name
            location.address summary
            location.sameAs "https://www.eventfinda.com.au/venue/#{url_slug}"
            location.geo point.to_schema_org_builder if point
          end
        end

      end
      class Category
        include ActiveModel::Model
        attr_accessor :id, :url_slug,:name,:parent_id, :count_current_events
      end
      class Event
        include ActiveModel::Model
        attr_accessor :address,
                      :artists,
                      :category,
                      :datetime_end,
                      :datetime_start,
                      :datetime_summary,
                      :description,
                      :external_reference,
                      :id,
                      :images,
                      :is_cancelled,
                      :is_featured,
                      :is_free,
                      :is_sold_out,
                      :location,
                      :location_summary,
                      :name,
                      :point,
                      :presented_by,
                      :restrictions,
                      :sessions,
                      :ticket_types,
                      :timezone,
                      :url,
                      :url_slug,
                      :username,
                      :video,
                      :web_sites

        def primary_image
          (images||[]).find(&:is_primary)
        end
        def category_url_slug
          return category.url_slug if category
        end
        def initialize raw
          super(raw)
          @location = Location.new(raw[:location]) if raw[:location]
          @images = raw[:images][:images].map { |raw_image|
            Image.new(raw_image) } if raw[:images]
          @category = Category.new(raw[:category]) if raw[:category]
        end
        def to_schema_org_builder
          Jbuilder.new do |result|
            result.set! "@context", CONTEXT
            result.set! "@type", :MusicEvent

            result.url url
            result.name name
            result.description description
            result.image primary_image.original_url if primary_image
            result.startDate  ActiveSupport::TimeZone[timezone].parse(datetime_start).iso8601 if timezone and datetime_start
            result.endDate ActiveSupport::TimeZone[timezone].parse(datetime_end).iso8601 if timezone and datetime_end
            result.eventStatus is_cancelled ? EVENT_STATUS[:cancelled] : EVENT_STATUS[:scheduled]
            result.eventAttendanceMode  "#{CONTEXT}/OfflineEventAttendanceMode"
            result.location  location.to_schema_org_builder if location
          end
        end
          def self.to_schema_org_events events
            Jbuilder.new do | result |
              result.array!(events) { |event| result.merge! event.to_schema_org_builder }
            end.target!
          end

      end
    end
  end
end
