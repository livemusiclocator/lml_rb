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
  end
end
