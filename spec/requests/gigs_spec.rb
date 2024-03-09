require "rails_helper"

describe "gigs" do
  it "when there are no gigs" do
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
              "href" => "http://www.example.com/gigs/query.json",
            },
            "next_seven_days" => {
              "href" => "http://www.example.com/gigs/query.json?date_from=2001-06-02&date_to=2001-06-09",
            },
            "next_weekend" => {
              "href" => "http://www.example.com/gigs/query.json?date_from=2001-06-08&date_to=2001-06-10",
            },
            "on_date" => {
              "href" => "http://www.example.com/gigs/query.json?date_from=date&date_to=date",
              "templated" => true,
            },
            "this_weekend" => {
              "href" => "http://www.example.com/gigs/query.json?date_from=2001-06-01&date_to=2001-06-03",
            },
            "today" => {
              "href" => "http://www.example.com/gigs/query.json?date_from=2001-06-02&date_to=2001-06-02",
            },
          },
        },
      ),
    )
  end
end
