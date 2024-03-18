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
      faraday.response :json, parser_options: { symbolize_names: true }
    end

    all_events = []
    page = 0

    query = config.query
    # TODO: make this cooler
    loop do
      break if page >= config.max_pages

      response = conn.get("/v2/events.json", query)
      all_events += response.body[:events].map { |raw| Lml::Processors::Eventfinda::Event.new(raw) }
      count = response.body[:@attributes][:count]
      break if (all_events.length >= count) || response.body[:events].empty?

      query = query.merge({ offset: all_events.length })
      page += 1
    end

    Lml::Upload.create(format: "schema_org_events", source: "eventfinda_com_au", content: Lml::Processors::Eventfinda::Event.to_schema_org_events(all_events.reject do |e|
                                                                                                                                                    config.skip_category_slugs.include?(e.category_url_slug)
                                                                                                                                                  end),)
  end
end
