# frozen_string_literal: true

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
      expect(JSON.parse(response.body)).to(
        eq(
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
        get "/gigs/query?location=melbourne&date_from=2001-06-08&date_to=2001-06-08"
        expect(JSON.parse(response.body)).to eq([])
      end

      it "returns empty result" do
        get "/gigs/for/melbourne/2001-06-08"
        expect(JSON.parse(response.body)).to eq([])
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
      end

      it "removes hidden gigs" do
        @gig.update!(hidden: true)
        get "/gigs/query?location=melbourne&date_from=2001-06-08&date_to=2001-06-08"
        expect(JSON.parse(response.body)).to eq([])
      end

      it "returns no gigs when location has no gigs" do
        get "/gigs/query?location=brisbane&date_from=2001-06-08&date_to=2001-06-08"
        expect(JSON.parse(response.body)).to eq([])
      end

      it "returns no gigs when there are no gigs for the specified dates" do
        get "/gigs/query?location=melbourne&date_from=2011-06-08&date_to=2011-06-08"
        expect(JSON.parse(response.body)).to eq([])
      end

      it "returns matching gigs when location and dates are specified" do
        get "/gigs/for/melbourne/2001-06-08"
        expect(JSON.parse(response.body)).to(
          eq(
            [
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
                "ticket_status" => nil,
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
            ],
          ),
        )
      end

      it "returns matching gigs when location and dates are specified" do
        get "/gigs/query?location=melbourne&date_from=2001-06-08&date_to=2001-08-08"
        expect(JSON.parse(response.body)).to(
          eq(
            [
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
                "ticket_status" => nil,
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
            ],
          ),
        )
      end
    end
  end
end
