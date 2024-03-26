# frozen_string_literal: true

require_relative "images"
require_relative "location"
module Eventfinda
  # TODO: do these live in schemaorg-specific code (or use gem)
  CONTEXT = "https://schema.org"
  EVENT_STATUS = {
    cancelled: "#{CONTEXT}/EventCancelled",
    scheduled: "#{CONTEXT}/EventScheduled",
  }.freeze
  class Category
    include ActiveModel::Model
    attr_accessor :id, :url_slug, :name, :parent_id, :count_current_events
  end

  class Event
    include ActiveModel::Model
    attr_accessor(
      :address,
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
      :web_sites,
    )

    def category_url_slug
      category&.url_slug
    end

    def initialize(raw)
      super(raw)
      @location = Location.new(raw[:location]) if raw[:location]
      @images = Images.new(raw[:images]) if raw[:images]
      @category = Category.new(raw[:category]) if raw[:category]
    end

    def to_schema_org_builder
      Jbuilder.new do |result|
        result.set! "@context", CONTEXT
        result.set! "@type", :MusicEvent

        result.url url
        result.name name
        result.description description
        result.timezone timezone if timezone
        result.startDate ActiveSupport::TimeZone[timezone].parse(datetime_start).iso8601 if timezone && datetime_start
        result.endDate ActiveSupport::TimeZone[timezone].parse(datetime_end).iso8601 if timezone && datetime_end
        result.eventStatus is_cancelled ? EVENT_STATUS[:cancelled] : EVENT_STATUS[:scheduled]
        result.eventAttendanceMode "#{CONTEXT}/OfflineEventAttendanceMode"
        result.image images.to_schema_org_builder if images
        result.location location.to_schema_org_builder if location
      end
    end

    def self.to_schema_org_events(events)
      Jbuilder.new do |result|
        result.array!(events) { |event| result.merge! event.to_schema_org_builder }
      end.target!
    end
  end
end
