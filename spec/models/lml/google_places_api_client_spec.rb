# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::GooglePlacesApiClient do
  before do
    # initial_delay: 0 because the point of the backoff is not waiting through it here.
    @client = described_class.new(api_key: "test-key", initial_delay: 0)
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

  # A 503 means Google's side is briefly at capacity, not that anything is wrong with the request -
  # one in a few hundred is normal, and without retrying it costs that venue its turn.
  describe "retrying" do
    it "rides out a 503 and returns the answer that follows" do
      stub_request(:post, described_class::FIND_URL)
        .to_return(status: 503, body: "unavailable")
        .then.to_return(status: 200, body: { places: [{ id: "place-espy" }] }.to_json)

      expect(@client.find("The Espy")).to eq("places" => [{ "id" => "place-espy" }])
    end

    it "rides out a 429 rate limit" do
      stub_request(:post, described_class::FIND_URL)
        .to_return(status: 429, body: "slow down")
        .then.to_return(status: 200, body: "{}")

      expect(@client.find("The Espy")).to eq({})
    end

    it "rides out a dropped connection" do
      stub_request(:post, described_class::FIND_URL)
        .to_raise(Faraday::ConnectionFailed)
        .then.to_return(status: 200, body: "{}")

      expect(@client.find("The Espy")).to eq({})
    end

    it "gives up after the attempt cap rather than sitting on a daily quota" do
      request = stub_request(:post, described_class::FIND_URL).to_return(status: 503, body: "unavailable")

      expect { @client.find("The Espy") }.to raise_error(described_class::Error, /503/)

      expect(request).to have_been_requested.times(described_class::MAX_ATTEMPTS)
    end

    # A 403 for an API that is not enabled is a fault no amount of waiting fixes, so retrying it
    # would only make a misconfiguration take four times as long to report.
    it "does not retry a fault that waiting cannot fix" do
      request = stub_request(:post, described_class::FIND_URL).to_return(
        status: 403,
        body: "Places API (New) has not been used in this project before",
      )

      expect { @client.find("The Espy") }.to raise_error(described_class::Error, /403/)

      expect(request).to have_been_requested.once
    end

    it "backs off further with each attempt" do
      stub_request(:post, described_class::FIND_URL).to_return(status: 503, body: "unavailable")
      client = described_class.new(api_key: "test-key", initial_delay: 1)
      slept = []
      allow(client).to receive(:sleep) { |seconds| slept << seconds }

      expect { client.find("The Espy") }.to raise_error(described_class::Error)

      expect(slept.length).to eq(described_class::MAX_ATTEMPTS - 1)
      expect(slept).to eq(slept.sort)
      expect(slept.first).to be_within(0.25).of(1)
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
