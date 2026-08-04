# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::GooglePlacesApiClient do
  before do
    @client = described_class.new(api_key: "test-key")
  end

  describe "#find" do
    it "posts the query and returns the parsed response" do
      request = stub_request(:post, described_class::FIND_URL).with(
        body: { textQuery: "The Espy, St Kilda", regionCode: "AU" },
        headers: {
          "X-Goog-Api-Key" => "test-key",
          "X-Goog-FieldMask" => described_class::FIND_FIELDS,
          "Content-Type" => "application/json",
        },
      ).to_return(status: 200, body: { places: [{ id: "place-espy" }] }.to_json)

      expect(@client.find("The Espy, St Kilda", region_code: "AU"))
        .to eq("places" => [{ "id" => "place-espy" }])

      expect(request).to have_been_requested
    end

    it "leaves the region out when there is none to bias towards" do
      stub_request(:post, described_class::FIND_URL)
        .with(body: { textQuery: "The Espy" })
        .to_return(status: 200, body: "{}")

      expect(@client.find("The Espy")).to eq({})
    end

    it "raises with the body, because an api key problem is only explained there" do
      stub_request(:post, described_class::FIND_URL)
        .to_return(status: 403, body: "Places API (New) has not been used in this project before")

      expect { @client.find("The Espy") }
        .to raise_error(described_class::Error, /403.*has not been used in this project/m)
    end
  end

  describe "#details" do
    it "asks for one place by id" do
      stub_request(:get, described_class::DETAILS_URL.sub("%<place_id>s", "place-espy"))
        .with(headers: { "X-Goog-FieldMask" => "*" })
        .to_return(status: 200, body: { id: "place-espy" }.to_json)

      expect(@client.details("place-espy")).to eq("id" => "place-espy")
    end
  end
end
