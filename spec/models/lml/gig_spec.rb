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

    describe "#suggest_tags!" do
      before do
        @gig = FactoryBot.create(:lml_gig, internal_description: "a night of smooth jazz")
        @parrot = instance_double(StochasticParrot, gist: %w[jazz lounge])
        allow(StochasticParrot).to receive(:new).and_return(@parrot)
      end

      it "stores what was suggested" do
        expect(@gig.suggest_tags!).to be_truthy

        expect(@parrot).to have_received(:gist).with("a night of smooth jazz")

        expect(@gig.reload.proposed_genre_tags).to eq(%w[jazz lounge])
      end

      # OpenAI declining - an exhausted credit balance, a rate limit - used to raise straight out of
      # here, turning every upload and admin edit that tripped over it into a 500.
      it "leaves the gig alone when nothing could be suggested" do
        allow(@parrot).to receive(:gist).and_return(nil)

        expect(@gig.suggest_tags!).to be_falsey

        expect(@gig.reload.proposed_genre_tags).to be_blank
      end

      it "does not ask when there is no description to go on" do
        @gig.update!(internal_description: nil)

        expect(@gig.suggest_tags!).to be_falsey

        expect(@parrot).not_to have_received(:gist)
      end

      it "does not ask again when tags have already been proposed" do
        @gig.update!(proposed_genre_tags: %w[jazz])

        expect(@gig.suggest_tags!).to be_falsey

        expect(@parrot).not_to have_received(:gist)
      end

      it "asks again when forced" do
        @gig.update!(proposed_genre_tags: %w[jazz])
        allow(@parrot).to receive(:gist).and_return(%w[funk])

        expect(@gig.suggest_tags!(force: true)).to be_truthy

        expect(@gig.reload.proposed_genre_tags).to eq(%w[funk])
      end
    end
  end
end
