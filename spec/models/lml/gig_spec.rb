require "rails_helper"

module Lml
  describe Gig do
    describe "#start_timestamp" do
      before { @gig = Gig.new }

      context "there is no date" do
        it "returns nil" do
          expect(@gig.start_timestamp).to be_nil
        end
      end

      context "there is a date" do
        before { @gig.date = "2024-01-01" }

        context "there is no start_time" do
          it "returns nil" do
            expect(@gig.start_timestamp).to be_nil
          end
        end

        context "there is a start_time" do
          before { @gig.start_time = "19:30" }

          context "there is no venue" do
            it "returns nil" do
              expect(@gig.start_timestamp).to be_nil
            end
          end

          context "when there is a venue" do
            before do
              @venue = Venue.create!(time_zone: "Australia/Melbourne")
              @gig.venue = @venue
            end

            it "converts to the local time in venue's timezone" do
              expect(@gig.start_timestamp.iso8601).to eq("2024-01-01T19:30:00+11:00")
            end

            it "correctly deals with daylight savings starting" do
              @gig.date = "2023-10-01"
              expect(@gig.start_timestamp.iso8601).to eq("2023-10-01T19:30:00+11:00")
            end

            it "correctly deals with daylight savings ending" do
              @gig.date = "2024-04-07"
              expect(@gig.start_timestamp.iso8601).to eq("2024-04-07T19:30:00+10:00")
            end
          end
        end
      end
    end

    describe "#finish_timestamp" do
      before { @gig = Gig.new }

      context "there is no date" do
        it "returns nil" do
          expect(@gig.finish_timestamp).to be_nil
        end
      end

      context "there is a date" do
        before { @gig.date = "2024-01-01" }

        context "there is no start_time" do
          it "returns nil" do
            expect(@gig.finish_timestamp).to be_nil
          end
        end

        context "there is a start_time" do
          before { @gig.start_time = "19:30" }

          context "there is no venue" do
            it "returns nil" do
              expect(@gig.finish_timestamp).to be_nil
            end
          end

          context "when there is a venue" do
            before do
              @venue = Venue.create!(time_zone: "Australia/Melbourne")
              @gig.venue = @venue
            end

            context "there is no duration" do
              it "returns nil" do
                expect(@gig.finish_timestamp).to be_nil
              end
            end

            context "there is a duration" do
              before { @gig.update!(duration: 120) }

              it "converts to the local time in venue's timezone" do
                expect(@gig.finish_timestamp.iso8601).to eq("2024-01-01T21:30:00+11:00")
              end

              it "correctly deals with daylight savings starting" do
                @gig.date = "2023-10-01"
                expect(@gig.finish_timestamp.iso8601).to eq("2023-10-01T21:30:00+11:00")
              end

              it "correctly deals with daylight savings ending" do
                @gig.date = "2024-04-07"
                expect(@gig.finish_timestamp.iso8601).to eq("2024-04-07T21:30:00+10:00")
              end
            end
          end
        end
      end
    end
  end
end
