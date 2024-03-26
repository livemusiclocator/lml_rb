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
      all_events += response.body[:events].map { |raw| Eventfinda::Event.new(raw) }
      count = response.body[:@attributes][:count]
      break if (all_events.length >= count) || response.body[:events].empty?

      query = query.merge({ offset: all_events.length })
      page += 1
    end

    # TODO: Maybe push more work into the eventfinda model/namespace thingo
    events = all_events.reject { |e| config.skip_category_slugs.include?(e.category_url_slug) }
    json = Eventfinda.to_schema_org_events(events)
    # this is silly but makes the upload content easier to read
    content = JSON.pretty_generate(JSON.parse(json))

    source = "eventfinda_com_au"
    upload = Lml::Upload.find_by(
      source: source,
      format: "schema_org_events",
    )

    if upload
      upload.update!(content: content)
    else
      upload = Lml::Upload.create!(
        source: source,
        format: "schema_org_events",
        content: content,
      )
    end

    upload.process!
  end
end
