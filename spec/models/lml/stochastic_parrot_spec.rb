# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::StochasticParrot do
  before do
    @url = "https://api.openai.com/v1/chat/completions"
    @parrot = described_class.new(access_token: "test-key")
  end

  def answering(tags)
    { choices: [{ message: { content: { gist_tags: tags }.to_json } }] }.to_json
  end

  describe "#gist" do
    it "returns the suggested tags, downcased" do
      request = stub_request(:post, @url)
                .with(headers: { "Authorization" => "Bearer test-key" })
                .to_return(status: 200, body: answering(%w[Jazz Lounge]))

      expect(@parrot.gist("a night of smooth jazz")).to eq(%w[jazz lounge])

      expect(request).to have_been_requested
    end

    it "sends the description to be tagged" do
      stub_request(:post, @url)
        .with(body: /a night of smooth jazz/)
        .to_return(status: 200, body: answering([]))

      expect(@parrot.gist("a night of smooth jazz")).to eq([])
    end

    # The failure that took uploads and admin edits down with a 500: OpenAI reports a spent credit
    # balance as a 429, so ruby-openai raises Faraday::TooManyRequestsError out of the save.
    it "returns nil when the credit balance has run out" do
      stub_request(:post, @url).to_return(
        status: 429,
        body: { error: { message: "You have no credits remaining.",
                         code: "credit_balance_exhausted", } }.to_json,
      )

      expect(@parrot.gist("a night of smooth jazz")).to be_nil
    end

    it "returns nil without asking when there is no key configured" do
      request = stub_request(:post, @url)

      expect(described_class.new(access_token: nil).gist("a night of smooth jazz")).to be_nil

      expect(request).not_to have_been_requested
    end

    it "returns nil when the key is rejected" do
      stub_request(:post, @url).to_return(status: 401, body: "{}")

      expect(@parrot.gist("a night of smooth jazz")).to be_nil
    end

    it "returns nil when OpenAI is broken" do
      stub_request(:post, @url).to_return(status: 500, body: "{}")

      expect(@parrot.gist("a night of smooth jazz")).to be_nil
    end

    it "returns nil when the connection drops" do
      stub_request(:post, @url).to_raise(Faraday::ConnectionFailed)

      expect(@parrot.gist("a night of smooth jazz")).to be_nil
    end

    it "returns nil when the answer is not the JSON it was asked for" do
      stub_request(:post, @url).to_return(
        status: 200,
        body: { choices: [{ message: { content: "sorry, no idea" } }] }.to_json,
      )

      expect(@parrot.gist("a night of smooth jazz")).to be_nil
    end

    it "returns nil when the answer is JSON without any tags in it" do
      stub_request(:post, @url).to_return(
        status: 200,
        body: { choices: [{ message: { content: { unhelpful: true }.to_json } }] }.to_json,
      )

      expect(@parrot.gist("a night of smooth jazz")).to be_nil
    end
  end
end
