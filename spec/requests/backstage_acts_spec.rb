# frozen_string_literal: true

require "rails_helper"

describe "backstage acts" do
  before do
    host! "www.livemusiclocator.com.au"
    @act = create(:lml_act, name: "Amyl and the Sniffers")
  end

  it "keeps somebody who is not an admin out" do
    sign_in create(:lml_user)

    get "/backstage/acts"
    expect(response).to redirect_to("/backstage")

    patch "/backstage/acts/#{@act.id}", params: { act: { name: "Renamed" } }
    expect(@act.reload.name).to eq("Amyl and the Sniffers")
  end

  describe "as an admin" do
    before { sign_in create(:lml_user, :admin) }

    it "searches the acts" do
      create(:lml_act, name: "Gut Health")

      get "/backstage/acts", params: { q: "gut" }

      expect(response.body).to include("Gut Health")
      expect(response.body).not_to include("Amyl and the Sniffers")
    end

    it "adds an act" do
      expect do
        post "/backstage/acts", params: {
          act: { name: "Gut Health", location: "melbourne", genre_list: "post-punk, art rock" },
        }
      end.to change(Lml::Act, :count).by(1)

      act = Lml::Act.find_by!(name: "Gut Health")
      expect(response).to redirect_to("/backstage/acts?q=Gut+Health")
      expect(act.location).to eq("melbourne")
      expect(act.genres).to eq(["post-punk", "art rock"])
    end

    it "refuses an act without a name" do
      expect { post "/backstage/acts", params: { act: { name: "" } } }.not_to change(Lml::Act, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it "updates an act" do
      patch "/backstage/acts/#{@act.id}", params: { act: { instagram: "amylandthesniffers", alias_list: "Amyl" } }

      @act.reload
      expect(@act.instagram).to eq("amylandthesniffers")
      expect(@act.aliases).to eq(["Amyl"])
    end
  end
end
