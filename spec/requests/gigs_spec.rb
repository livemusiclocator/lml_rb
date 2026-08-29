# frozen_string_literal: true

# rubocop:disable Layout/LineLength
require "rails_helper"

describe "gigs" do
  # should match the 'api.*' defined routes with this
  # (todo: add web request tests which will need www.)
  before { host! "api.lml.live" }
  describe "index" do
    it "signposts the documentation" do
      get "/gigs"

      expect(response.parsed_body).to eq(
        "name" => "Live Music Locator API",
        "documentation" => "http://api.lml.live/docs",
        "attribution" => "Data courtesy of Live Music Locator: https://lml.live",
      )
    end

    # The bare api host answers with the same signpost. It used to 301 to the
    # consumer gig guide - a leftover from when it redirected to /admin and the
    # api host was the whole app, long before www existed.
    it "answers on the bare api host too" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["documentation"]).to eq("http://api.lml.live/docs")
    end

    # Mounted at /api/gigs on www as well, where /docs is a different route to
    # the same controller - so the signpost has to follow the host it is on.
    it "points at the documentation on the host it was asked on" do
      host! "www.livemusiclocator.com.au"

      get "/api/gigs"

      expect(response.parsed_body["documentation"]).to eq("http://www.livemusiclocator.com.au/docs")
    end
  end

  describe "show" do
    before do
      @venue = Lml::Venue.create!(
        name: "The Gig Place",
        address: "the address",
        postcode: 1234,
        location: "melbourne",
        time_zone: "Australia/Melbourne",
        capacity: 500,
        website: "https://gigplace.com.au",
      )
      @gig = Lml::Gig.create!(
        name: "The One Gig You Should Not Miss Out On",
        description: "This is some text that is going to continue to persuade you to attend this gig but with less capital letters.",
        venue: @venue,
        date: "2001-06-08",
        status: :confirmed,
        ticket_status: :sold_out,
        ticketing_url: "the ticketing url",
        information_tags: %w[all-ages free],
        genre_tags: %w[post-punk dream-pop],
        series: "ohm",
        category: "music",
      )
      @main_act = Lml::Act.create!(
        name: "The Really Quite Good Music People",
        genres: %w[good loud people],
        spotify: "spot123",
      )
      @first_support = Lml::Act.create!(name: "first support")
      @second_support = Lml::Act.create!(name: "second support")
      Lml::Set.create!(
        act: @first_support,
        gig: @gig,
        start_time: "18:00",
        duration: 30,
        stage: "main",
      )
      Lml::Set.create!(
        act: @main_act,
        gig: @gig,
        start_time: "20:00",
        duration: 60,
        stage: "main",
      )
      Lml::Set.create!(
        act: @second_support,
        gig: @gig,
        start_time: "19:00",
        duration: 30,
        stage: "main",
      )
      Lml::Price.create!(
        gig: @gig,
        amount: "75",
        description: "GA",
      )
    end

    it "returns gig" do
      get "/gigs/#{@gig.id}"
      expect(response.parsed_body).to eq(
        {
          "date" => "2001-06-08",
          "description" => "This is some text that is going to continue to persuade you to attend this gig but with less capital letters.",
          "duration" => nil,
          "id" => @gig.id,
          "name" => "The One Gig You Should Not Miss Out On",
          "series" => "ohm",
          "category" => "music",
          "prices" => [
            {
              "amount" => "$75.00",
              "description" => "GA",
            },
          ],
          "sets" => [
            {
              "act" => {
                "genres" => nil,
                "id" => @first_support.id,
                "name" => "first support",
              },
              "start_time" => "18:00",
              "start_timestamp" => "2001-06-08T18:00:00.000+10:00",
              "duration" => 30,
              "finish_time" => "18:30",
              "finish_timestamp" => "2001-06-08T18:30:00.000+10:00",
            },
            {
              "act" => {
                "genres" => nil,
                "id" => @second_support.id,
                "name" => "second support",
              },
              "start_time" => "19:00",
              "start_timestamp" => "2001-06-08T19:00:00.000+10:00",
              "duration" => 30,
              "finish_time" => "19:30",
              "finish_timestamp" => "2001-06-08T19:30:00.000+10:00",
            },
            {
              "act" => {
                "genres" => %w[good loud people],
                "id" => @main_act.id,
                "name" => "The Really Quite Good Music People",
                "spotify_url" => "https://open.spotify.com/artist/spot123",
              },
              "start_time" => "20:00",
              "start_timestamp" => "2001-06-08T20:00:00.000+10:00",
              "duration" => 60,
              "finish_time" => "21:00",
              "finish_timestamp" => "2001-06-08T21:00:00.000+10:00",
            },
          ],
          "start_time" => nil,
          "start_timestamp" => nil,
          "finish_time" => nil,
          "finish_timestamp" => nil,
          "status" => "confirmed",
          "ticket_status" => "sold_out",
          "genre_tags" => %w[post-punk dream-pop],
          "information_tags" => %w[all-ages free],
          "ticketing_url" => "the ticketing url",
          "venue" => {
            "address" => "the address",
            "postcode" => "1234",
            "capacity" => 500,
            "id" => @venue.id,
            "latitude" => nil,
            "longitude" => nil,
            "name" => "The Gig Place",
            "website" => "https://gigplace.com.au",
            "tags" => [],
            "vibe" => nil,
            "location_url" => nil,
          },
        },
      )
    end
  end

  describe "query" do
    context "when there are no provided params" do
      it "returns empty result" do
        get "/gigs/query"
        expect(response.parsed_body).to eq([])
      end
    end

    context "when there are no gigs" do
      it "returns empty result" do
        get "/gigs/query?location=melbourne&date_from=2001-06-08&date_to=2001-06-08"
        expect(response.parsed_body).to eq([])
      end

      it "returns empty result" do
        get "/gigs/for/melbourne/2001-06-08"
        expect(response.parsed_body).to eq([])
      end
    end

    context "when there are gigs" do
      before do
        @venue = Lml::Venue.create!(
          name: "The Gig Place",
          location: "melbourne",
          address: "the address",
          postcode: 1234,
          time_zone: "Australia/Melbourne",
          capacity: 500,
          website: "https://gigplace.com.au",
        )
        @stkilda_venue = Lml::Venue.create!(
          name: "The Escry",
          location: "stkilda",
          address: "the address",
          postcode: 3182, # St Kilda Postcode
          time_zone: "Australia/Melbourne",
          capacity: 100,
          website: "https://definitelyTheEscryNotATypo.com.au",
        )
        @stkilda_venue_two = Lml::Venue.create!(
          name: "The Mildred Hotel",
          location: "stkilda",
          address: "the address",
          postcode: 9999, # NOT St Kilda Postcode
          time_zone: "Australia/Melbourne",
          capacity: 100,
          website: "https://mildrediscoolyeah.com.au",
        )

        @gig = Lml::Gig.create!(
          name: "The One Gig You Should Not Miss Out On",
          description: "This is some text that is going to continue to persuade you to attend this gig but with less capital letters.",
          venue: @venue,
          date: "2001-06-08",
          status: :confirmed,
          ticketing_url: "the ticketing url",
          information_tags: %w[all-ages free],
          genre_tags: %w[post-punk dream-pop],
          series: "ohm",
          category: "music",
        )
        @main_act = Lml::Act.create!(
          name: "The Really Quite Good Music People",
          genres: %w[good loud people],
          spotify: "spot123",
        )
        @first_support = Lml::Act.create!(name: "first support")
        @second_support = Lml::Act.create!(name: "second support")
        Lml::Set.create!(
          act: @first_support,
          gig: @gig,
          start_time: "18:00",
          duration: 30,
          stage: "main",
        )
        Lml::Set.create!(
          act: @main_act,
          gig: @gig,
          start_time: "20:00",
          duration: 60,
          stage: "main",
        )
        Lml::Set.create!(
          act: @second_support,
          gig: @gig,
          start_time: "19:00",
          duration: 30,
          stage: "main",
        )
        Lml::Price.create!(
          gig: @gig,
          amount: "75",
          description: "GA",
        )
        Lml::Gig.create!(
          name: "The Other Gig You Should Not Miss Out On",
          venue: @venue,
          date: "2001-08-08",
        )
        @gig_in_stkilda = Lml::Gig.create!(
          name: "A gig in st kilda",
          venue: @stkilda_venue,
          date: "2001-06-08",
        )
        @another_gig_in_stkilda = Lml::Gig.create!(
          name: "Another gig in st kilda",
          venue: @stkilda_venue_two,
          date: "2001-06-08",
        )
      end

      it "removes hidden gigs" do
        @gig.update!(hidden: true)
        @gig_in_stkilda.update!(hidden: true)
        @another_gig_in_stkilda.update!(hidden: true)
        get "/gigs/query?location=melbourne&date_from=2001-06-08&date_to=2001-06-08"
        expect(response.parsed_body).to eq([])
      end

      it "returns no gigs when location has no gigs" do
        get "/gigs/query?location=brisbane&date_from=2001-06-08&date_to=2001-06-08"
        expect(response.parsed_body).to eq([])
      end

      it "returns no gigs when there are no gigs for the specified dates" do
        get "/gigs/query?location=melbourne&date_from=2011-06-08&date_to=2011-06-08"
        expect(response.parsed_body).to eq([])
      end

      # "anywhere" is the main edition's selectable locations, not literally every
      # venue - a location left off that list is hidden, so gigs can be entered
      # against it without turning up in the gig guide.
      describe "location = anywhere" do
        before do
          @hidden_venue = Lml::Venue.create!(
            name: "The Bendigo Bandstand",
            location: "bendigo",
            address: "the address",
            postcode: 3550,
            time_zone: "Australia/Melbourne",
            capacity: 100,
            website: "https://bendigobandstand.com.au",
          )
          Lml::Gig.create!(name: "A gig in bendigo", venue: @hidden_venue, date: "2001-06-08")

          # The location column holds both spellings, so a capitalised venue has
          # to come back for a lowercase identifier.
          @capitalised_venue = Lml::Venue.create!(
            name: "The Shouty Venue",
            location: "Melbourne",
            address: "the address",
            postcode: 3000,
            time_zone: "Australia/Melbourne",
            capacity: 100,
            website: "https://shoutyvenue.com.au",
          )
          Lml::Gig.create!(name: "A gig at a capitalised venue", venue: @capitalised_venue, date: "2001-06-08")
        end

        # ExplorerConfig strips any identifier with no locations row behind it, so
        # the locations have to exist before the config will keep them.
        def main_edition_selecting(identifiers)
          identifiers.each do |identifier|
            Web::Location.find_or_create_by!(internal_identifier: identifier) do |location|
              location.name = identifier.capitalize
              location.latitude = -37.8
              location.longitude = 144.9
            end
          end

          Web::ExplorerConfig.create!(
            edition_id: "main",
            allow_all_locations: true,
            default_location: "anywhere",
            selectable_locations: identifiers,
          )
        end

        def gig_names
          response.parsed_body.map { |gig| gig["name"] }
        end

        it "returns gigs in the locations the main edition selects" do
          main_edition_selecting(%w[melbourne stkilda])

          get "/gigs/query?location=anywhere&date_from=2001-06-08&date_to=2001-06-08"

          expect(gig_names).to contain_exactly(
            "The One Gig You Should Not Miss Out On",
            "A gig at a capitalised venue",
            "A gig in st kilda",
            "Another gig in st kilda",
          )
        end

        it "leaves out gigs in a location the main edition does not select" do
          main_edition_selecting(%w[melbourne stkilda])

          get "/gigs/query?location=anywhere&date_from=2001-06-08&date_to=2001-06-08"

          expect(gig_names).not_to include("A gig in bendigo")
        end

        it "still fetches a hidden location for whoever asks for it by name" do
          main_edition_selecting(%w[melbourne stkilda])

          get "/gigs/query?location=bendigo&date_from=2001-06-08&date_to=2001-06-08"

          expect(gig_names).to contain_exactly("A gig in bendigo")
        end

        it "includes a location once the main edition selects it" do
          main_edition_selecting(%w[melbourne stkilda bendigo])

          get "/gigs/query?location=anywhere&date_from=2001-06-08&date_to=2001-06-08"

          expect(gig_names).to include("A gig in bendigo")
        end

        it "falls back to every location when no main edition is configured" do
          get "/gigs/query?location=anywhere&date_from=2001-06-08&date_to=2001-06-08"

          expect(gig_names).to include("A gig in bendigo")
        end

        it "falls back to every location when the selectable list is empty" do
          main_edition_selecting([])

          get "/gigs/query?location=anywhere&date_from=2001-06-08&date_to=2001-06-08"

          expect(gig_names).to include("A gig in bendigo")
        end
      end

      describe "matching sub-geographies of Melbourne" do
        it "returns venues with location=stkilda and location=melbourne when location=melbourne" do
          get "/gigs/query?location=melbourne&date_from=2001-06-08&date_to=2001-08-08"
          expect(response.parsed_body).to match_unordered_json([
                                                                      { name: "A gig in st kilda",
                                                                        venue: { name: "The Escry" }, },
                                                                      { name: "Another gig in st kilda",
                                                                        venue: { name: "The Mildred Hotel" }, },
                                                                      { name: "The One Gig You Should Not Miss Out On",
                                                                        venue: { name: "The Gig Place" },  },
                                                                    ])
        end
        # Every other location is matched with ILIKE. Melbourne was the exception
        # for a year, an exact-match list of the two spellings anyone had seen.
        it "returns a melbourne venue whatever its location was capitalised as" do
          shouty_venue = Lml::Venue.create!(
            name: "The Shouty Venue",
            location: "MELBOURNE",
            address: "the address",
            postcode: 3000,
            time_zone: "Australia/Melbourne",
            capacity: 100,
            website: "https://shoutyvenue.com.au",
          )
          Lml::Gig.create!(name: "A gig at a shouty venue", venue: shouty_venue, date: "2001-06-08")

          get "/gigs/query?location=melbourne&date_from=2001-06-08&date_to=2001-08-08"

          expect(response.parsed_body.map { |gig| gig["name"] }).to include("A gig at a shouty venue")
        end

        it "returns venues with location=stkilda when location=stkilda" do
          get "/gigs/query?location=stkilda&date_from=2001-06-08&date_to=2001-08-08"
          expect(response.parsed_body).to match_unordered_json([
                                                                      { name: "A gig in st kilda",
                                                                        venue: { name: "The Escry" }, },
                                                                      { name: "Another gig in st kilda",
                                                                        venue: { name: "The Mildred Hotel" }, },
                                                                    ])
        end
      end
    end
  end

  describe "feed" do
    before do
      @venue = Lml::Venue.create!(
        name: "The Gig Place",
        address: "the address",
        postcode: 1234,
        location: "melbourne",
        time_zone: "Australia/Melbourne",
        capacity: 500,
        website: "https://gigplace.com.au",
      )
      @second_gig = Lml::Gig.create!(
        name: "Second gig",
        description: "This is some text that is going to continue to persuade you to attend this gig but with less capital letters.",
        venue: @venue,
        date: "2001-06-09",
        status: :confirmed,
        ticket_status: :sold_out,
        ticketing_url: "the ticketing url",
        information_tags: %w[all-ages free],
        genre_tags: %w[post-punk dream-pop],
        series: "ohm",
        category: "music",
      )
      @first_gig = Lml::Gig.create!(
        name: "First gig",
        description: "This is some text that is going to continue to persuade you to attend this gig but with less capital letters.",
        venue: @venue,
        date: "2001-06-08",
        status: :confirmed,
        ticket_status: :sold_out,
        ticketing_url: "the ticketing url",
        information_tags: %w[all-ages free],
        genre_tags: %w[post-punk dream-pop],
        series: "ohm",
        category: "music",
      )
      @more_than_seven_days = Lml::Gig.create!(
        name: "A gig more than seven days away",
        description: "This is some text that is going to continue to persuade you to attend this gig but with less capital letters.",
        venue: @venue,
        date: "2001-07-08",
        status: :confirmed,
        ticket_status: :sold_out,
        ticketing_url: "the ticketing url",
        information_tags: %w[all-ages free],
        genre_tags: %w[post-punk dream-pop],
        series: "ohm",
        category: "music",
      )

      travel_to(Time.iso8601("2001-06-08T00:00:00Z")) do
        get "/gigs/feed.rss"
      end

      @doc = Nokogiri::XML(response.body)
    end

    it "returns a valid rss document" do
      expect(@doc.at_xpath("/rss/@version").value).to eq("2.0")
    end

    it "has the correct title" do
      expect(@doc.at_xpath("/rss/channel/title").text).to eq("Live Music Locator - gig feed")
    end

    it "has the correct description" do
      expect(@doc.at_xpath("/rss/channel/description").text).to eq("Discover all live music events in the City of Yarra.")
    end

    it "has the correct link" do
      expect(@doc.at_xpath("/rss/channel/link").text).to eq("https://lml.live")
    end

    it "has the correct language" do
      expect(@doc.at_xpath("/rss/channel/language").text).to eq("en")
    end

    it "shows items in chronological order" do
      expect(@doc.xpath("//item/title")[0].text).to include("First gig")
      expect(@doc.xpath("//item/title")[1].text).to include("Second gig")
    end

    it "only shows next seven days worth of gigs" do
      expect(@doc.xpath("//item/title").map(&:text)).not_to include("A gig more than seven days away")
    end

    it "has the correct gig information" do
      expect(@doc.xpath("//item/title").first.text).to eq("First gig - The Gig Place (melbourne) - Fri, 08 Jun 2001")
      expect(@doc.xpath("//item/description").first.text).to eq("First gig - The Gig Place (melbourne) - Fri, 08 Jun 2001")
      expect(@doc.xpath("//item/author").first.text).to eq("LML")
      expect(@doc.xpath("//item/pubDate").first.text).to eq(@first_gig.updated_at.rfc822)
      expect(@doc.xpath("//item/link").first.text).to eq("https://lml.live/gigs/#{@first_gig.id}")
      expect(@doc.xpath("//item/guid").first.text).to eq("https://lml.live/gigs/#{@first_gig.id}")
    end
  end

  # The seven day cap on a query's date range, and the TOKENS shared secret that
  # lifts it for internal callers - see TokenAccess.
  describe "query date range cap" do
    before do
      @previous_tokens = ENV.fetch("TOKENS", nil)
      ENV["TOKENS"] = "demo-token, other-token"

      @venue = create(:lml_venue, location: "melbourne")
      @soon = create(:lml_gig, name: "Within the week", venue: @venue, date: "2001-06-05")
      @later = create(:lml_gig, name: "Beyond the week", venue: @venue, date: "2001-06-20")
    end

    after { ENV["TOKENS"] = @previous_tokens }

    it "truncates an anonymous caller's range to seven days" do
      get "/gigs/query?location=melbourne&date_from=2001-06-01&date_to=2001-06-30"

      expect(response.parsed_body.map { |gig| gig["name"] }).to eq(["Within the week"])
    end

    it "honours the full range for a caller with a token" do
      get "/gigs/query?location=melbourne&date_from=2001-06-01&date_to=2001-06-30&token=demo-token"

      expect(response.parsed_body.map { |gig| gig["name"] }).to eq(["Within the week", "Beyond the week"])
    end

    it "truncates for a token we did not issue" do
      get "/gigs/query?location=melbourne&date_from=2001-06-01&date_to=2001-06-30&token=guessed"

      expect(response.parsed_body.map { |gig| gig["name"] }).to eq(["Within the week"])
    end

    it "truncates for a blank token, which an empty TOKENS entry would otherwise match" do
      ENV["TOKENS"] = "demo-token,,other-token"

      get "/gigs/query?location=melbourne&date_from=2001-06-01&date_to=2001-06-30&token="

      expect(response.parsed_body.map { |gig| gig["name"] }).to eq(["Within the week"])
    end

    it "leaves a range already inside seven days alone" do
      get "/gigs/query?location=melbourne&date_from=2001-06-01&date_to=2001-06-06"

      expect(response.parsed_body.map { |gig| gig["name"] }).to eq(["Within the week"])
    end
  end
end
# rubocop:enable Layout/LineLength
