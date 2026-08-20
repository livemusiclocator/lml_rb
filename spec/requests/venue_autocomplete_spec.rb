# frozen_string_literal: true

require "rails_helper"

describe "venue autocomplete" do
  before do
    host! "api.lml.live"

    @previous_tokens = ENV.fetch("TOKENS", nil)
    ENV["TOKENS"] = "demo-token, other-token"

    @tote = create(:lml_venue, name: "The Tote", location: "melbourne")
    @bridge = create(:lml_venue, name: "Bridge Hotel", location: "castlemaine")
  end

  after { ENV["TOKENS"] = @previous_tokens }

  it "lists every venue for a caller with a token" do
    get "/venues/autocomplete", params: { token: "demo-token" }

    expect(JSON.parse(response.body)).to eq(
      [
        { "id" => @bridge.id, "label" => "Bridge Hotel (castlemaine)" },
        { "id" => @tote.id, "label" => "The Tote (melbourne)" },
      ],
    )
  end

  it "accepts any of the configured tokens" do
    get "/venues/autocomplete", params: { token: "other-token" }

    expect(response).to have_http_status(:ok)
  end

  it "refuses a caller with no token" do
    get "/venues/autocomplete"

    expect(response).to have_http_status(:unauthorized)
  end

  it "refuses a caller with a token we did not issue" do
    get "/venues/autocomplete", params: { token: "guessed" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "refuses a blank token, which an empty TOKENS entry would otherwise match" do
    ENV["TOKENS"] = "demo-token,,other-token"

    get "/venues/autocomplete", params: { token: "" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "refuses everyone when TOKENS is unset rather than letting everyone in" do
    ENV["TOKENS"] = nil

    get "/venues/autocomplete", params: { token: "demo-token" }

    expect(response).to have_http_status(:unauthorized)
  end
end
