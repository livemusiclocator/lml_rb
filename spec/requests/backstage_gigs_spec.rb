# frozen_string_literal: true

require "rails_helper"

describe "backstage gigs" do
  before do
    host! "www.livemusiclocator.com.au"

    @manager = create(:lml_user)
    @venue = create(:lml_venue, name: "The Tote")
    @other_venue = create(:lml_venue, name: "The Corner")
    Lml::VenueManager.create!(user: @manager, venue: @venue)
    sign_in @manager

    @params = {
      gig: {
        name: "Gut Health",
        date: "2026-11-14",
        start_time: "20:00",
        finish_time: "23:30",
        status: "confirmed",
        ticket_status: "",
        ticketing_url: "https://tickets.example.com/gut-health",
        set_list: "Gut Health | 9:30pm | 10:30pm | main\nSupport Act",
        price_list: "25.00 | General admission",
        genre_tag_list: "post-punk\n",
        description: "A night of it.",
      },
    }
  end

  describe "adding a gig" do
    it "creates it at the venue, with its sets, prices and times" do
      expect { post "/backstage/venues/#{@venue.id}/gigs", params: @params }.to change(Lml::Gig, :count).by(1)

      gig = Lml::Gig.last
      expect(response).to redirect_to("/backstage/venues/#{@venue.id}")
      expect(gig.venue).to eq(@venue)
      expect(gig.date).to eq(Date.new(2026, 11, 14))
      expect(gig.start_time).to eq("20:00")
      expect(gig.finish_time).to eq("23:30")
      expect(gig.sets.map { |set| set.act.name }).to contain_exactly("Gut Health", "Support Act")
      expect(gig.prices.map(&:description)).to eq(["General admission"])
      expect(gig.genre_tags).to eq(["post-punk"])
      expect(gig.ticket_status).to be_nil
    end

    it "refuses a gig without a name or a date, and keeps nothing" do
      @params[:gig].merge!(name: "", date: "")

      expect { post "/backstage/venues/#{@venue.id}/gigs", params: @params }.not_to change(Lml::Gig, :count)
      expect(Lml::Set.count).to eq(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it "refuses a start time it cannot read, rather than erroring" do
      @params[:gig].merge!(start_time: "late")

      expect { post "/backstage/venues/#{@venue.id}/gigs", params: @params }.not_to change(Lml::Gig, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Start time isn&#39;t a time we can read")
    end

    it "does not find a venue somebody else manages" do
      expect { post "/backstage/venues/#{@other_venue.id}/gigs", params: @params }.not_to change(Lml::Gig, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "editing a gig" do
    before do
      @gig = create(:lml_gig, venue: @venue, name: "Old name", date: "2026-11-14")
      @gig.set_list = "Old Act"
    end

    it "updates it, replacing its sets" do
      patch "/backstage/gigs/#{@gig.id}", params: @params

      expect(response).to redirect_to("/backstage/venues/#{@venue.id}")
      @gig.reload
      expect(@gig.name).to eq("Gut Health")
      expect(@gig.finish_time).to eq("23:30")
      expect(@gig.sets.map { |set| set.act.name }).to contain_exactly("Gut Health", "Support Act")
    end

    it "clears a start time that is emptied" do
      @gig.update!(start_time: "19:00")
      @params[:gig].merge!(start_time: "", finish_time: "")

      patch "/backstage/gigs/#{@gig.id}", params: @params

      expect(@gig.reload.start_time).to be_nil
    end

    it "leaves the gig and its sets alone when the change is refused" do
      @params[:gig][:name] = ""

      patch "/backstage/gigs/#{@gig.id}", params: @params

      expect(response).to have_http_status(:unprocessable_entity)
      @gig.reload
      expect(@gig.name).to eq("Old name")
      expect(@gig.sets.map { |set| set.act.name }).to eq(["Old Act"])
    end

    it "does not find a gig at a venue somebody else manages" do
      other_gig = create(:lml_gig, venue: @other_venue, name: "Not yours")

      patch "/backstage/gigs/#{other_gig.id}", params: @params

      expect(response).to have_http_status(:not_found)
      expect(other_gig.reload.name).to eq("Not yours")
    end
  end

  describe "as an admin" do
    before do
      sign_in create(:lml_user, :admin)
    end

    it "adds a gig at a venue they do not manage" do
      expect { post "/backstage/venues/#{@other_venue.id}/gigs", params: @params }.to change(@other_venue.gigs, :count).by(1)
    end

    it "edits a gig at a venue they do not manage" do
      gig = create(:lml_gig, venue: @other_venue, name: "Old name")

      patch "/backstage/gigs/#{gig.id}", params: @params

      expect(gig.reload.name).to eq("Gut Health")
    end
  end
end
