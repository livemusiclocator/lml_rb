require "rails_helper"

describe "gigs" do
  describe "index" do
    it "returns links to query endpoints" do
      travel_to(Time.iso8601("2001-06-02T00:00:00Z")) do
        get "/gigs"
      end

      expect(JSON.parse(response.body)).to(
        eq(
          {
            "links" => {
              "_self" => {
                "href" => "http://www.example.com/gigs",
              },
              "default" => {
                "href" => "http://www.example.com/gigs/query",
              },
              "next_seven_days" => {
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-02&date_to=2001-06-09&location=castlemaine",
              },
              "next_weekend" => {
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-08&date_to=2001-06-10&location=castlemaine",
              },
              "on_date" => {
                "href" => "http://www.example.com/gigs/query?date_from=date&date_to=date&location=castlemaine",
                "templated" => true,
              },
              "this_weekend" => {
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-01&date_to=2001-06-03&location=castlemaine",
              },
              "today" => {
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-02&date_to=2001-06-02&location=castlemaine",
              },
            },
          },
        ),
      )
    end
  end

  describe "query" do
    context "when there are no provided params" do
      it "returns empty result" do
        get "/gigs/query"
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context "when there are no gigs" do
      it "returns empty result" do
        get "/gigs/query?location=a+location&date_from=2001-06-08&date_to=2001-06-08"
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context "when there are gigs" do
      before do
        @venue = Lml::Venue.create!(
          name: "The Gig Place",
          location: "melbourne",
          capacity: 500,
          website: "https://gigplace.com.au",
        )
        @act = Lml::Act.create!(
          name: "The Really Quite Good Music People",
          genres: %w[good loud people],
        )
        @gig = Lml::Gig.create!(
          name: "The One Gig You Should Not Miss Out On",
          headline_act: @act,
          venue: @venue,
          date: "2001-06-08",
          status: :confirmed,
          ticketing_url: "the ticketing url",
          tags: %w[all-ages free lbmf],
        )
        Lml::Price.create!(
          gig: @gig,
          amount: "75",
          description: "GA",
        )
      end

      it "removes hidden gigs" do
        @gig.update!(hidden: true)
        get "/gigs/query?location=lbmf&date_from=2001-06-08&date_to=2001-06-08"
        expect(JSON.parse(response.body)).to eq([])
      end

      it "returns matching gigs when location and dates are specified" do
        get "/gigs/query?location=lbmf&date_from=2001-06-08&date_to=2001-06-08"
        expect(JSON.parse(response.body)).to(
          eq(
            [
              {
                "date" => "2001-06-08",
                "finish_time" => nil,
                "headline_act" => {
                  "genres" => %w[good loud people],
                  "id" => @act.id,
                  "name" => "The Really Quite Good Music People",
                },
                "id" => @gig.id,
                "name" => "The One Gig You Should Not Miss Out On",
                "prices" => [
                  {
                    "amount" => "$75.00",
                    "description" => "GA",
                  }
                ],
                "sets" => [],
                "start_time" => nil,
                "tags" => %w[all-ages free lbmf],
                "ticketing_url" => "the ticketing url",
                "venue" => {
                  "address" => nil,
                  "capacity" => 500,
                  "id" => @venue.id,
                  "latitude" => nil,
                  "longitude" => nil,
                  "name" => "The Gig Place",
                  "website" => "https://gigplace.com.au",
                },
              },
            ],
          ),
        )
      end
    end
  end
end
