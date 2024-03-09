require "rails_helper"

describe "gigs" do
  describe "index" do
    it "returns links to query endpoints" do
      travel_to(Time.iso8601("2001-06-01T19:00:00Z")) do
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
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-02&date_to=2001-06-09",
              },
              "next_weekend" => {
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-08&date_to=2001-06-10",
              },
              "on_date" => {
                "href" => "http://www.example.com/gigs/query?date_from=date&date_to=date",
                "templated" => true,
              },
              "this_weekend" => {
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-01&date_to=2001-06-03",
              },
              "today" => {
                "href" => "http://www.example.com/gigs/query?date_from=2001-06-02&date_to=2001-06-02",
              },
            },
          },
        ),
      )
    end
  end

  describe "query" do
    context "when there are no gigs" do
      it "returns empty result" do
        get "/gigs/query"
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context "when there are gigs" do
      before do
        @venue = Lml::Venue.create!(name: "The Gig Place")
        @act = Lml::Act.create!(
          name: "The Really Quite Good Music People",
          genres: %w[good loud people]
        )
        @gig = Lml::Gig.create!(
          name: "The One Gig You Should Not Miss Out On",
          headline_act: @act,
          venue: @venue,
          date: "2001-06-08",
          status: :confirmed,
        )
      end

      it "returns matching gigs when dates are specified" do
        get "/gigs/query?date_from=2001-06-08&date_to=2001-06-08"
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
                "sets" => [],
                "start_time" => nil,
                "venue" => {
                  "address" => nil,
                  "id" => @venue.id,
                  "latitude" => nil,
                  "longitude" => nil,
                  "name" => "The Gig Place",
                },
              },
            ],
          ),
        )
      end
    end
  end
end
