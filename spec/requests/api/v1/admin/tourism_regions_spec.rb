# frozen_string_literal: true

require "rails_helper"

describe "admin api tourism regions" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @headers = { "Authorization" => "Bearer #{Lml::ApiToken.issue!(user: @admin, name: "Import").plaintext}" }

    @yarra = create(:web_tourism_region, name: "Yarra Valley", internal_identifier: "yarra_valley")
    @goldfields = create(:web_tourism_region, name: "Goldfields", internal_identifier: "goldfields")
  end

  def body
    JSON.parse(response.body)
  end

  it "lists regions in name order with the id a venue is set to" do
    get "/v1/admin/tourism_regions", headers: @headers

    expect(body["tourism_regions"]).to eq(
      [
        { "id" => @goldfields.id, "internal_identifier" => "goldfields", "name" => "Goldfields" },
        { "id" => @yarra.id, "internal_identifier" => "yarra_valley", "name" => "Yarra Valley" },
      ],
    )
  end

  it "paginates like every other collection" do
    get "/v1/admin/tourism_regions", params: { per_page: 1 }, headers: @headers

    expect(body["tourism_regions"].size).to eq(1)
    expect(body["meta"]).to eq({ "page" => 1, "per_page" => 1, "total" => 2 })
  end

  it "needs an admin token like everything else here" do
    get "/v1/admin/tourism_regions"

    expect(response).to have_http_status(:unauthorized)
  end
end
