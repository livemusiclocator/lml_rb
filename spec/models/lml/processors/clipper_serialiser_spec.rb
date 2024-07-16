require "rails_helper"

module Lml
  module Processors
    describe ClipperSerialiser do
      before do
        @venue = Venue.create!(time_zone: "Australia/Melbourne")
        @today = Date.iso8601("2024-03-01")
        @second = Gig.create!(
          name: "second",
          date: @today,
          venue: @venue,
        )
        @first = Gig.create!(
          name: "first",
          date: @today - 1.day,
          venue: @venue,
          start_time: "19:00",
          finish_time: "01:30",
          status: :draft,
          ticketing_url: "https://tickets.com/123",
          url: "https://gigs.com/567",
          series: "gig series",
          category: "gig category",
          genre_tags: %w[genre1 genre2],
          information_tags: %w[info1 info2],
          internal_description: "one\ntwo\nthree",
        )
        @old = Gig.create!(
          name: "old",
          date: @today - 2.days,
          venue: @venue,
        )
      end

      it "exports all non blank information" do
        travel_to(@today) do
          expect(ClipperSerialiser.new(@venue).serialise).to(
            eq(<<~TEXT)
            ---
            id: #{@first.id}
            name: first
            date: 2024-02-29
            start_time: 19:00
            finish_time: 01:30
            status: draft
            tickets: https://tickets.com/123
            url: https://gigs.com/567
            series: gig series
            category: gig category
            internal_description: one two three
            genre: genre1
            genre: genre2
            information: info1
            information: info2
            ---
            id: #{@second.id}
            name: second
            date: 2024-03-01
            status: confirmed
            TEXT
          )
        end
      end
    end
  end
end
