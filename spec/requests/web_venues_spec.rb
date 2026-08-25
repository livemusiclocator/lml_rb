# frozen_string_literal: true

require "rails_helper"

# The html venue page on www, the act page's opposite number. The json the spa
# then fetches is Api::VenuesController's - see spec/requests/venues_spec.
describe "the venue page" do
  before do
    host! "www.livemusiclocator.com.au"

    @venue = Lml::Venue.create!(
      name: "The Tote",
      address: "67-71 Johnston St, Collingwood VIC 3066",
      postcode: 3066,
      location: "melbourne",
      time_zone: "Australia/Melbourne",
    )
    @act = Lml::Act.create!(name: "Amyl and the Sniffers", country: "Australia")
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
    get "/venues/#{@venue.id}"

    expect(response).to have_http_status(:ok)
  end

  it "titles the page with the venue" do
    get "/venues/#{@venue.id}"

    expect(response.body).to include("<title>The Tote")
  end

  it "embeds the venue as json ld" do
    get "/venues/#{@venue.id}"

    expect(json_ld).to include(
      "@type" => "Place",
      "name" => "The Tote",
      "address" => "67-71 Johnston St, Collingwood VIC 3066",
    )
  end

  # Place will not accept a blank address, and a venue we have not resolved yet
  # has none. The page has to survive that rather than 500.
  it "still renders a venue with no address" do
    nowhere = Lml::Venue.create!(name: "Nowhere", location: "melbourne", time_zone: "Australia/Melbourne")

    get "/venues/#{nowhere.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<title>Nowhere")
  end

  it "mounts the spa" do
    get "/venues/#{@venue.id}"

    expect(response.body).to include('id="root"')
    expect(response.body).to include("window.APP_CONFIG")
  end

  describe "the fallback a crawler without javascript sees" do
    it "names the venue and its address" do
      get "/venues/#{@venue.id}"

      expect(response.body).to include("The Tote")
      expect(response.body).to include("67-71 Johnston St, Collingwood VIC 3066")
    end

    it "lists upcoming gigs and who is playing" do
      create_gig("Sniffers Live", Date.current + 3)

      get "/venues/#{@venue.id}"

      expect(response.body).to include("Sniffers Live")
      expect(response.body).to include("Amyl and the Sniffers")
    end

    it "says so when there are none" do
      get "/venues/#{@venue.id}"

      expect(response.body).to include("No upcoming gigs")
    end

    it "leaves out hidden and draft gigs" do
      create_gig("Hush Hush", Date.current + 3, hidden: true)
      create_gig("Still Cooking", Date.current + 4, status: :draft)

      get "/venues/#{@venue.id}"

      expect(response.body).not_to include("Hush Hush")
      expect(response.body).not_to include("Still Cooking")
    end
  end

  describe "a venue we do not have" do
    it "404s and says it was a venue" do
      get "/venues/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Venue not found")
    end
  end

  # Parsed rather than matched as a string: the gem pretty prints outside
  # production and minifies in it, so an assertion on the raw body passes here
  # and says nothing about what is actually deployed.
  def json_ld
    block = response.body[%r{<script type="application/ld\+json">(.*?)</script>}m, 1]
    JSON.parse(block)
  end

  describe "routing", type: :routing do
    it "routes a uuid to the web venues controller" do
      id = SecureRandom.uuid

      expect(get: "http://www.livemusiclocator.com.au/venues/#{id}")
        .to route_to(controller: "web/venues", action: "show", id: id)
    end

    it "routes the edition version too" do
      id = SecureRandom.uuid

      expect(get: "http://www.livemusiclocator.com.au/editions/geelong/venues/#{id}")
        .to route_to(controller: "web/venues", action: "show", id: id, edition_id: "geelong")
    end

    it "does not route anything that is not a uuid" do
      expect(get: "http://www.livemusiclocator.com.au/venues/not-a-uuid")
        .to route_to(controller: "web/errors", action: "not_found", path: "venues/not-a-uuid")
    end
  end
end
