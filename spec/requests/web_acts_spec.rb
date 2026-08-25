# frozen_string_literal: true

require "rails_helper"

# The html act page on www, which the spa's client side /acts/:id route lands on.
# The json it then fetches is Api::ActsController's - see spec/requests/acts_spec.
describe "the act page" do
  before do
    host! "www.livemusiclocator.com.au"

    @venue = Lml::Venue.create!(
      name: "The Tote",
      address: "67-71 Johnston St, Collingwood VIC 3066",
      postcode: 3066,
      location: "melbourne",
      time_zone: "Australia/Melbourne",
    )
    @act = Lml::Act.create!(
      name: "Amyl and the Sniffers",
      country: "Australia",
      genres: ["punk", "garage rock"],
      instagram: "amylandthesniffers",
    )
    Web::ExplorerConfig.find_by(edition_id: "main") || Web::ExplorerConfig.create!(
      edition_id: "main",
      allow_all_locations: true,
      selectable_locations: ["melbourne"],
      default_location: "melbourne",
    )
  end

  def create_gig(name, date, attributes = {})
    gig = Lml::Gig.create!({ name: name, venue: @venue, date: date, status: :confirmed }.merge(attributes))
    Lml::Set.create!(gig: gig, act: @act, start_offset: 1200)
    gig
  end

  it "renders" do
    get "/acts/#{@act.id}"

    expect(response).to have_http_status(:ok)
  end

  it "titles the page with the act" do
    get "/acts/#{@act.id}"

    expect(response.body).to include("<title>Amyl and the Sniffers")
  end

  # The whole reason this page is server rendered rather than left to the spa.
  it "embeds the act as json ld" do
    get "/acts/#{@act.id}"

    expect(response.body).to include('"@type": "MusicGroup"')
    expect(response.body).to include('"name": "Amyl and the Sniffers"')
    expect(response.body).to include("https://www.instagram.com/amylandthesniffers")
  end

  it "mounts the spa" do
    get "/acts/#{@act.id}"

    expect(response.body).to include('id="root"')
    expect(response.body).to include("window.APP_CONFIG")
  end

  describe "the fallback a crawler without javascript sees" do
    it "names the act and its genres" do
      get "/acts/#{@act.id}"

      expect(response.body).to include("Amyl and the Sniffers")
      expect(response.body).to include("punk, garage rock")
    end

    it "lists upcoming gigs" do
      create_gig("Sniffers Live", Date.current + 3)

      get "/acts/#{@act.id}"

      expect(response.body).to include("Sniffers Live")
      expect(response.body).to include("The Tote")
    end

    it "says so when there are none" do
      get "/acts/#{@act.id}"

      expect(response.body).to include("No upcoming gigs")
    end

    # Same visible scope as the json endpoint - the fallback is public html.
    it "leaves out hidden and draft gigs" do
      create_gig("Hush Hush", Date.current + 3, hidden: true)
      create_gig("Still Cooking", Date.current + 4, status: :draft)

      get "/acts/#{@act.id}"

      expect(response.body).not_to include("Hush Hush")
      expect(response.body).not_to include("Still Cooking")
    end
  end

  describe "an act we do not have" do
    it "404s" do
      get "/acts/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end

    # The 404 used to say "Gig not found" whatever you had asked for.
    it "says it was an act it could not find" do
      get "/acts/#{SecureRandom.uuid}"

      expect(response.body).to include("Act not found")
      expect(response.body).to include("details about the act you are looking for")
    end

    it "still says gig on a gig it cannot find" do
      get "/gigs/#{SecureRandom.uuid}"

      expect(response.body).to include("Gig not found")
    end
  end

  describe "routing", type: :routing do
    it "routes a uuid to the web acts controller" do
      id = SecureRandom.uuid

      expect(get: "http://www.livemusiclocator.com.au/acts/#{id}")
        .to route_to(controller: "web/acts", action: "show", id: id)
    end

    it "routes the edition version too" do
      id = SecureRandom.uuid

      expect(get: "http://www.livemusiclocator.com.au/editions/geelong/acts/#{id}")
        .to route_to(controller: "web/acts", action: "show", id: id, edition_id: "geelong")
    end

    it "does not route anything that is not a uuid" do
      expect(get: "http://www.livemusiclocator.com.au/acts/not-a-uuid")
        .to route_to(controller: "web/errors", action: "not_found", path: "acts/not-a-uuid")
    end
  end
end
