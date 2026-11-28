# frozen_string_literal: true

require "rails_helper"

describe "admin api venue export and bulk update" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @headers = { "Authorization" => "Bearer #{Lml::ApiToken.issue!(user: @admin, name: "Import").plaintext}" }

    @melbourne = create(:web_tourism_region, name: "Melbourne", internal_identifier: "melbourne")
    @goldfields = create(:web_tourism_region, name: "Goldfields", internal_identifier: "goldfields")
    @tote = create(:lml_venue, name: "The Tote", location: "melbourne", capacity: 400)
    @bridge = create(:lml_venue, name: "Bridge Hotel", location: "castlemaine")
  end

  def bulk_update(content)
    post "/v1/admin/venues/bulk_update", params: { content: content }, headers: @headers, as: :json
  end

  # The response blocks, as key => value hashes, without the separators.
  def blocks
    response.body.split(/^---\n/).compact_blank.map do |block|
      block.lines.to_h { |line| line.chomp.split(": ", 2).then { |key, value| [key.delete_suffix(":"), value.to_s] } }
    end
  end

  describe "exporting" do
    it "writes each venue as a block of the fields a caller may set" do
      @tote.update!(tourism_region: @melbourne, tags: ["band room", "late"], lga: "City of Yarra")

      get "/v1/admin/venues/export", params: { q: "tote" }, headers: @headers

      expect(response.media_type).to eq("text/plain")
      expect(response.body).to start_with("---\nid: #{@tote.id}\nname: The Tote\n")
      expect(response.body).to include(
        "capacity: 400\n",
        "lga: City of Yarra\n",
        "tourism_region: Melbourne\n",
        "tags: band room | late\n",
      )
    end

    it "leaves out fields with no value, which on the way back in means leave them alone" do
      get "/v1/admin/venues/export", params: { q: "bridge" }, headers: @headers

      expect(response.body).not_to include("capacity:")
      expect(response.body).not_to include("tourism_region:")
    end

    it "keeps the line breaks in notes" do
      @tote.update!(notes: "Load in at the back\n\nAsk for Sam")

      get "/v1/admin/venues/export", params: { q: "tote" }, headers: @headers

      expect(response.body).to include("notes: Load in at the back\nnotes:\nnotes: Ask for Sam\n")
    end

    it "filters to venues still without a tourism region" do
      @tote.update!(tourism_region: @melbourne)

      get "/v1/admin/venues/export", params: { tourism_region_id: "none" }, headers: @headers

      expect(response.body).to include("name: Bridge Hotel")
      expect(response.body).not_to include("name: The Tote")
    end

    it "filters by location" do
      get "/v1/admin/venues/export", params: { location: "castlemaine" }, headers: @headers

      expect(response.body).to include("name: Bridge Hotel")
      expect(response.body).not_to include("name: The Tote")
    end

    it "is read back in as no change at all" do
      @tote.update!(tourism_region: @melbourne, tags: ["late"], notes: "one\n\ntwo", latitude: -37.8, lga: "Yarra")
      get "/v1/admin/venues/export", headers: @headers

      bulk_update(response.body)

      expect(blocks.map { |block| block["result"] }).to eq(%w[unchanged unchanged])
    end

    it "pages through the venues, a hundred at most, and gives the total in a header" do
      get "/v1/admin/venues/export", params: { per_page: 1, page: 2 }, headers: @headers

      expect(response.body.scan(/^name: (.*)$/).flatten).to eq(["The Tote"])
      expect(response.headers["X-Total-Count"]).to eq("2")
    end

    it "refuses to dump every venue at once however many are asked for" do
      create_list(:lml_venue, 101)

      get "/v1/admin/venues/export", params: { per_page: 5000 }, headers: @headers

      expect(response.body.scan(/^id: /).length).to eq(100)
      expect(response.headers["X-Total-Count"]).to eq("103")
    end

    it "counts only the venues the filters select" do
      get "/v1/admin/venues/export", params: { location: "castlemaine" }, headers: @headers

      expect(response.headers["X-Total-Count"]).to eq("1")
    end

    it "needs an admin token like everything else here" do
      get "/v1/admin/venues/export"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "bulk updating" do
    it "sets a field on each venue and says so per block" do
      bulk_update(<<~CLIPPER)
        id: #{@tote.id}
        capacity: 350
        ---
        id: #{@bridge.id}
        tourism_region: Goldfields
      CLIPPER

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(blocks).to eq(
        [
          { "id" => @tote.id, "capacity" => "350", "result" => "updated" },
          { "id" => @bridge.id, "tourism_region" => "Goldfields", "result" => "updated" },
        ],
      )
      expect(@tote.reload.capacity).to eq(350)
      expect(@bridge.reload.tourism_region).to eq(@goldfields)
    end

    it "takes the text as the whole body too" do
      post "/v1/admin/venues/bulk_update",
        params: "id: #{@tote.id}\ncapacity: 350\n",
        headers: @headers.merge("Content-Type" => "text/plain; charset=utf-8")

      expect(blocks.first["result"]).to eq("updated")
      expect(@tote.reload.capacity).to eq(350)
    end

    it "leaves fields a block does not mention alone" do
      @tote.update!(lga: "City of Yarra")

      bulk_update("id: #{@tote.id}\ncapacity: 350\n")

      expect(@tote.reload.lga).to eq("City of Yarra")
    end

    it "clears a field given with no value" do
      @tote.update!(lga: "City of Yarra", tourism_region: @melbourne)

      bulk_update("id: #{@tote.id}\nlga:\ntourism_region:\n")

      expect(@tote.reload.lga).to be_nil
      expect(@tote.tourism_region).to be_nil
    end

    it "reports a block that changes nothing as unchanged" do
      bulk_update("id: #{@tote.id}\ncapacity: 400\n")

      expect(blocks.first["result"]).to eq("unchanged")
    end

    it "finds a tourism region by internal identifier or id as well as by name" do
      bulk_update(<<~CLIPPER)
        id: #{@tote.id}
        tourism_region: goldfields
        ---
        id: #{@bridge.id}
        tourism_region_id: #{@melbourne.id}
      CLIPPER

      expect(@tote.reload.tourism_region).to eq(@goldfields)
      expect(@bridge.reload.tourism_region).to eq(@melbourne)
    end

    it "sets tags from a | separated list" do
      bulk_update("id: #{@tote.id}\ntags: band room | late\n")

      expect(@tote.reload.tags).to eq(["band room", "late"])
    end

    it "joins repeated notes lines back into one note" do
      bulk_update("id: #{@tote.id}\nnotes: Load in at the back\nnotes:\nnotes: Ask for Sam\n")

      expect(@tote.reload.notes).to eq("Load in at the back\n\nAsk for Sam")
    end

    it "carries on past a bad block, saving the rest" do
      bulk_update(<<~CLIPPER)
        id: #{@tote.id}
        time_zone: Mars/Olympus
        ---
        id: #{@bridge.id}
        capacity: 120
      CLIPPER

      expect(blocks.map { |block| block["result"] }).to eq(%w[invalid updated])
      expect(blocks.first["error"]).to include("invalid time zone")
      expect(@tote.reload.time_zone).not_to eq("Mars/Olympus")
      expect(@bridge.reload.capacity).to eq(120)
    end

    it "refuses a number it cannot read rather than clearing the column" do
      bulk_update("id: #{@tote.id}\ncapacity: lots\n")

      expect(blocks.first).to include("result" => "invalid", "error" => "capacity must be a whole number")
      expect(@tote.reload.capacity).to eq(400)
    end

    it "refuses a tourism region that does not exist" do
      bulk_update("id: #{@tote.id}\ntourism_region: Atlantis\n")

      expect(blocks.first).to include("result" => "invalid", "error" => 'there is no tourism region "Atlantis"')
    end

    it "refuses a field it does not know, which is most likely a typo" do
      bulk_update("id: #{@tote.id}\ncapcity: 350\n")

      expect(blocks.first).to include("result" => "invalid", "error" => "capcity is not a field that can be set")
    end

    it "refuses fields only google or a merge write" do
      bulk_update("id: #{@tote.id}\ngoogle_place_id: ChIJ-somewhere\n")

      expect(blocks.first["result"]).to eq("invalid")
    end

    it "refuses a field given twice" do
      bulk_update("id: #{@tote.id}\ncapacity: 350\ncapacity: 360\n")

      expect(blocks.first).to include("result" => "invalid", "error" => "capacity is given more than once")
    end

    it "needs an id in every block rather than creating a venue" do
      expect { bulk_update("name: A New Venue\n") }.not_to change(Lml::Venue, :count)

      expect(blocks.first).to include("result" => "invalid")
    end

    it "reports an id that names no venue" do
      missing = SecureRandom.uuid

      bulk_update("id: #{missing}\ncapacity: 1\n")

      expect(blocks.first).to include("result" => "not_found", "error" => "no venue has the id #{missing}")
    end

    it "follows a merged venue's id to the venue it was merged into" do
      merged_id = SecureRandom.uuid
      @tote.update!(merged_venue_ids: [merged_id])

      bulk_update("id: #{merged_id}\ncapacity: 350\n")

      expect(blocks.first).to eq(
        {
          "id" => @tote.id,
          "capacity" => "350",
          "merged_from" => merged_id,
          "result" => "updated",
        },
      )
      expect(@tote.reload.capacity).to eq(350)
    end

    it "answers with a file that can be corrected and sent back whole" do
      bulk_update(<<~CLIPPER)
        id: #{@tote.id}
        capacity: lots
        ---
        id: #{@bridge.id}
        capacity: 120
      CLIPPER

      corrected = response.body.sub("capacity: lots", "capacity: 450")
      bulk_update(corrected)

      expect(blocks.map { |block| block["result"] }).to eq(%w[updated unchanged])
      expect(blocks.first).not_to have_key("error")
      expect(@tote.reload.capacity).to eq(450)
    end

    it "keeps comment lines and blank lines as they were sent" do
      bulk_update("# the band room\nid: #{@tote.id}\ncapacity: 350\n\n---\nid: #{@bridge.id}\ncapacity: 120\n")

      expect(response.body).to eq(
        "# the band room\nid: #{@tote.id}\ncapacity: 350\nresult: updated\n\n" \
        "---\nid: #{@bridge.id}\ncapacity: 120\nresult: updated\n",
      )
    end

    it "refuses more venues than it can save inside one request" do
      stub_const("Lml::VenueBulkUpdate::LIMIT", 1)

      bulk_update("id: #{@tote.id}\ncapacity: 1\n---\nid: #{@bridge.id}\ncapacity: 2\n")

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["error"]).to include("limit is 1")
      expect(@tote.reload.capacity).to eq(400)
    end

    it "refuses content with no venues in it" do
      bulk_update("\n# nothing here\n")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "needs an admin token like everything else here" do
      post "/v1/admin/venues/bulk_update", params: { content: "id: #{@tote.id}\ncapacity: 1\n" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(@tote.reload.capacity).to eq(400)
    end
  end
end
