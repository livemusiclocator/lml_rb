# frozen_string_literal: true

require "rails_helper"

describe "admin api gig bulk update" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @headers = { "Authorization" => "Bearer #{Lml::ApiToken.issue!(user: @admin, name: "Import").plaintext}" }

    @tote = create(:lml_venue, name: "The Tote", location: "melbourne", time_zone: "Australia/Melbourne")
    @vine = create(:lml_venue, name: "Golden Vine Hotel", location: "bendigo", time_zone: "Australia/Melbourne")
  end

  def bulk_update(content, venue_id: @tote.id, source: "cli")
    post "/v1/admin/gigs/bulk_update",
      params: { content: content, venue_id: venue_id, source: source }.compact,
      headers: @headers,
      as: :json
  end

  # The response blocks, as key => value hashes, without the separators.
  def blocks
    response.body.split(/^---\n/).compact_blank.map do |block|
      block.lines.to_h { |line| line.chomp.split(":", 2).then { |key, value| [key, value.to_s.strip] } }
    end
  end

  it "creates the gigs and gives each block its result and new id" do
    bulk_update(<<~CLIPPER)
      name: Sniffers Live
      date: 2026-09-01
      time: 20:00
      acts: Amyl and the Sniffers | Cable Ties
      price: 30.00 | presale
      ---
      name: Quiet Tuesday
      date: 2026-09-02
    CLIPPER

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    sniffers = Lml::Gig.find_by!(name: "Sniffers Live")
    quiet = Lml::Gig.find_by!(name: "Quiet Tuesday")
    expect(blocks.map { |block| block.slice("id", "result") }).to eq(
      [
        { "id" => sniffers.id, "result" => "created" },
        { "id" => quiet.id, "result" => "created" },
      ],
    )
    expect(sniffers).to have_attributes(venue: @tote, source: "cli", start_time: "20:00", uploaded_by: @admin)
    expect(sniffers.sets.count).to eq(2)
  end

  it "keeps no upload" do
    expect { bulk_update("name: Quiet Tuesday\ndate: 2026-09-02\n") }.not_to change(Lml::Upload, :count)

    expect(Lml::Gig.find_by!(name: "Quiet Tuesday").upload).to be_nil
  end

  it "takes the text as the whole body too, with the venue and source in the query" do
    post "/v1/admin/gigs/bulk_update?venue_id=#{@tote.id}&source=cli",
      params: "name: Quiet Tuesday\ndate: 2026-09-02\n",
      headers: @headers.merge("Content-Type" => "text/plain; charset=utf-8")

    expect(blocks.first["result"]).to eq("created")
    expect(Lml::Gig.find_by!(name: "Quiet Tuesday").source).to eq("cli")
  end

  it "updates a gig it already holds, matched on name, date and venue" do
    gig = create(:lml_gig, name: "Quiet Tuesday", date: Date.new(2026, 9, 2), venue: @tote)

    bulk_update("name: Quiet Tuesday\ndate: 2026-09-02\ntime: 19:30\n")

    expect(blocks.first).to include("id" => gig.id, "result" => "updated")
    expect(gig.reload.start_time).to eq("19:30")
  end

  it "updates by id, and does not add a second id line" do
    gig = create(:lml_gig, name: "Old name", date: Date.new(2026, 9, 2), venue: @tote)

    bulk_update("id: #{gig.id}\nname: New name\ndate: 2026-09-02\n")

    expect(response.body).to eq("id: #{gig.id}\nname: New name\ndate: 2026-09-02\nresult: updated\n")
    expect(gig.reload.name).to eq("New name")
  end

  it "deletes, and counts deleting a gig that is already gone as done" do
    gig = create(:lml_gig, name: "Cancelled", date: Date.new(2026, 9, 2), venue: @tote)

    bulk_update("id: #{gig.id}\nname: Cancelled\ndate: 2026-09-02\nstatus: delete\n")
    expect(blocks.first["result"]).to eq("deleted")
    expect(Lml::Gig.exists?(gig.id)).to be(false)

    bulk_update(response.body)
    expect(blocks.first).to include("result" => "deleted")
    expect(blocks.first).not_to have_key("error")
  end

  it "lists every gig a block with weeks became" do
    bulk_update("name: Quiet Tuesday\ndate: 2026-09-02\nweeks: 3\n")

    ids = Lml::Gig.where(name: "Quiet Tuesday").order(:date).pluck(:id)
    expect(ids.length).to eq(3)
    expect(blocks.first).to include("gig_ids" => ids.join(", "), "result" => "created")
    expect(blocks.first).not_to have_key("id")
  end

  it "carries on past a bad block, saving the rest" do
    bulk_update(<<~CLIPPER)
      name: Bad date
      date: someday
      ---
      date: 2026-09-03
      ---
      name: Quiet Tuesday
      date: 2026-09-02
    CLIPPER

    expect(blocks.map { |block| block["result"] }).to eq(%w[invalid invalid created])
    expect(blocks[0]["error"]).to eq("'someday' is not a valid date")
    expect(blocks[1]["error"]).to eq("A gig name is required")
    expect(Lml::Gig.exists?(name: "Quiet Tuesday")).to be(true)
  end

  it "reports an id that names no gig" do
    missing = SecureRandom.uuid

    bulk_update("id: #{missing}\nname: Ghost\ndate: 2026-09-02\n")

    expect(blocks.first).to include("result" => "not_found", "error" => "A gig with id #{missing} could not be found")
  end

  it "needs a venue for an entry that names none" do
    bulk_update("name: Nowhere\ndate: 2026-09-02\n", venue_id: nil)

    expect(blocks.first).to include("result" => "invalid", "error" => "A venue is required")
  end

  it "uses a block's own venue over the default" do
    bulk_update("name: At the Vine\ndate: 2026-09-02\nvenue_id: #{@vine.id}\n")

    expect(Lml::Gig.find_by!(name: "At the Vine").venue).to eq(@vine)
  end

  it "answers with a file that can be corrected and sent back whole" do
    bulk_update("name: Bad date\ndate: someday\n---\nname: Quiet Tuesday\ndate: 2026-09-02\n")

    bulk_update(response.body.sub("date: someday", "date: 2026-09-05"))

    expect(blocks.map { |block| block["result"] }).to eq(%w[created updated])
    expect(blocks.first).not_to have_key("error")
    expect(Lml::Gig.where(name: "Quiet Tuesday").count).to eq(1)
  end

  it "comes back under its id after a rename in review, rather than as a second copy" do
    bulk_update("name: Quiet Tuesday\ndate: 2026-09-02\n")
    Lml::Gig.find_by!(name: "Quiet Tuesday").update!(name: "Quiet Tuesday w/ Somebody")

    expect { bulk_update(response.body) }.not_to change(Lml::Gig, :count)
  end

  it "refuses a default venue that does not exist" do
    bulk_update("name: Quiet Tuesday\ndate: 2026-09-02\n", venue_id: SecureRandom.uuid)

    expect(response).to have_http_status(:unprocessable_content)
    expect(Lml::Gig.count).to eq(0)
  end

  it "refuses more gigs than it can save inside one request" do
    stub_const("Lml::GigBulkUpdate::LIMIT", 1)

    bulk_update("name: One\ndate: 2026-09-02\n---\nname: Two\ndate: 2026-09-03\n")

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["error"]).to include("limit is 1")
    expect(Lml::Gig.count).to eq(0)
  end

  it "refuses content with no gigs in it" do
    bulk_update("\n# nothing yet\n")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "puts back the time zone it borrowed for each venue" do
    perth = create(:lml_venue, name: "Perth", time_zone: "Australia/Perth")

    expect { bulk_update("name: West\ndate: 2026-09-02\n", venue_id: perth.id) }.not_to(change { Time.zone.name })
  end

  it "needs an admin token like everything else here" do
    post "/v1/admin/gigs/bulk_update", params: { content: "name: X\ndate: 2026-09-02\n" }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(Lml::Gig.count).to eq(0)
  end
end
