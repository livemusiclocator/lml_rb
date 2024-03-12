# frozen_string_literal: true
class FetchEventfindaJob < ApplicationJob

  queue_as :default

  def perform
    config = Rails.application.config_for(:eventfinda)
    raise "Eventfinda integration is disabled" unless config.enabled

    conn = Faraday.new(url: config.endpoint_url) do |faraday|
      faraday.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
      faraday.request :authorization, :basic, config.credentials[:username], config.credentials[:password]
      faraday.request :json
      faraday.response :json, parser_options: {symbolize_names: true}
    end

    all_events = []
    page = 0
    loop do
      response = conn.get("/v2/events.json", offset: page * config.page_size, rows: config.page_size)
      all_events += response.body[:events]
      count = response.body[:@attributes][:count]
      break if (all_events.length >= count) or response.body[:events].empty?
      page += 1
      # TEMP? or probably not the way these things go.
      break if page > 5
    end
    Lml::Upload.create(format: "eventfinda_events", source: "eventfinda_com_au", content: {events: all_events}.to_json)
    end
end
