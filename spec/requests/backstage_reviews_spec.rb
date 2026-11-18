# frozen_string_literal: true

require "rails_helper"

describe "backstage reviews" do
  before do
    host! "www.livemusiclocator.com.au"

    @admin = create(:lml_user, :admin)
    sign_in @admin

    @tote = create(:lml_venue, name: "The Tote", location: "melbourne")
    @vine = create(:lml_venue, name: "Golden Vine Hotel", location: "bendigo")

    @mine = upload_by(@admin, "research-markryall", @tote)
    @theirs = upload_by(create(:lml_user, :admin), "lmb", @vine)

    @dole = create(:lml_gig, name: "DOLE NIGHT w/ Contact Sport + Brodown", date: Date.current + 1, venue: @tote,
                             source: "research-markryall", upload: @mine, proposed_acts: ["Contact Sport", "Brodown"],
                             proposed_genre_tags: ["punk"])
    @karaoke = create(:lml_gig, name: "Kickarse Karaoke", date: Date.current + 2, venue: @tote,
                                source: "research-markryall", upload: @mine)
    @vine_gig = create(:lml_gig, name: "Andrew Swift", date: Date.current + 3, venue: @vine, source: "lmb",
                                 upload: @theirs)
    @checked = create(:lml_gig, name: "Already done", date: Date.current + 1, venue: @tote, checked: true)
    @past = create(:lml_gig, name: "Last week", date: Date.current - 7, venue: @tote)
  end

  def upload_by(user, source, venue)
    Lml::Upload.create!(user: user, source: source, venue: venue, format: "clipper",
                        time_zone: "Australia/Melbourne", content: "")
  end

  describe "who can see it" do
    it "turns away somebody who is not an admin" do
      sign_in create(:lml_user)

      get "/backstage/reviews"

      expect(response).to redirect_to("/backstage")
    end
  end

  describe "the queue" do
    # Every gig starts out unchecked, so the whole of it is nobody's to work
    # through. It starts from the gigs your own uploads put in.
    it "starts from your own uploads" do
      get "/backstage/reviews"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("research-markryall")
      expect(response.body).to include(%(href="/backstage/reviews/#{@dole.id}?who=mine"))
      expect(response.body).not_to include("Golden Vine Hotel</a>")
    end

    it "shows everybody's when asked, a venue at a time" do
      get "/backstage/reviews", params: { who: "everyone" }

      expect(response.body).to include("Golden Vine Hotel</a>")
      expect(response.body).to include("The Tote</a>")
      # Golden Vine's gig comes before The Tote's.
      expect(response.body).to include(%(href="/backstage/reviews/#{@vine_gig.id}?who=everyone"))
    end

    it "narrows to one source" do
      get "/backstage/reviews", params: { who: "everyone", source: "lmb" }

      expect(response.body).to include(%(href="/backstage/reviews/#{@vine_gig.id}?source=lmb&amp;who=everyone"))
      expect(response.body).not_to include("research-markryall</a>")
    end

    it "narrows to one location" do
      get "/backstage/reviews", params: { who: "everyone", location: "bendigo" }

      expect(response.body).to include("Golden Vine Hotel</a>")
      expect(response.body).not_to include("The Tote</a>")
    end
  end

  describe "one gig" do
    # The gig as the public sees it, to check what review is about to change.
    it "links to the gig on the gig guide" do
      get "/backstage/reviews/#{@dole.id}"

      expect(response.body).to include(%(href="/gigs/#{@dole.id}"))
    end

    # Research sends a site's gig even where LML has another that night under a
    # different name - a second gig, or a rename that is now two copies.
    it "shows what else is at the venue that night" do
      typed = create(:lml_gig, name: "Contact Sport + Brodown", date: @dole.date, venue: @tote)
      create(:lml_gig, name: "Next night", date: @dole.date + 1, venue: @tote)

      get "/backstage/reviews/#{@dole.id}"

      expect(response.body).to include("Also at this venue that night")
      expect(response.body).to include(%(href="/backstage/reviews/#{typed.id}?who=mine"))
      expect(response.body).not_to include("Next night")
    end

    it "says nothing about the night when the gig is alone on it" do
      get "/backstage/reviews/#{@vine_gig.id}"

      expect(response.body).not_to include("Also at this venue that night")
    end

    it "offers the suggested acts and genres when nothing is confirmed yet" do
      get "/backstage/reviews/#{@dole.id}"

      expect(response.body).to include("Contact Sport\nBrodown")
      expect(response.body).to include("punk")
    end
  end

  describe "answering" do
    def answer(gig, decision, **rest)
      patch "/backstage/reviews/#{gig.id}", params: {
        decision: decision,
        gig: { name: gig.name, set_list: "", genre_tag_list: "" },
      }.merge(rest)
    end

    it "saves the lineup and genres, marks it checked and moves on" do
      answer(@dole, "save", gig: { name: "Contact Sport", set_list: "Contact Sport\nBrodown", genre_tag_list: "punk\n" })

      @dole.reload
      expect(@dole.name).to eq("Contact Sport")
      expect(@dole.sets.map { |set| set.act.name }).to contain_exactly("Contact Sport", "Brodown")
      expect(@dole.genre_tags).to eq(["punk"])
      expect(@dole).to be_checked
      expect(response).to redirect_to("/backstage/reviews/#{@karaoke.id}?who=mine")
    end

    it "refuses to save without a name, and keeps the gig unchecked" do
      answer(@dole, "save", gig: { name: "", set_list: "Contact Sport", genre_tag_list: "" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(@dole.reload).not_to be_checked
      expect(@dole.sets).to be_empty
    end

    it "hides what is not a gig, and marks it checked so it leaves the queue" do
      answer(@karaoke, "hide")

      @karaoke.reload
      expect(@karaoke).to be_hidden
      expect(@karaoke).to be_checked
    end

    it "skips without changing anything, and does not come back to it" do
      answer(@dole, "skip")
      expect(@dole.reload).not_to be_checked
      expect(response).to redirect_to("/backstage/reviews/#{@karaoke.id}?who=mine")

      answer(@karaoke, "skip")
      expect(response).to redirect_to("/backstage/reviews?who=mine")
    end

    it "keeps to the queue it was started on" do
      answer(@dole, "skip", who: "everyone")
      answer(@karaoke, "skip", who: "everyone")

      expect(response).to redirect_to("/backstage/reviews/#{@vine_gig.id}?who=everyone")
    end
  end
end
