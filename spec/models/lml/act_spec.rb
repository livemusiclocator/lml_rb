# frozen_string_literal: true

require "rails_helper"

describe Lml::Act do
  describe "handle setters" do
    before { @act = create(:lml_act, instagram: "https://www.instagram.com/amylsniffers") }

    it "keeps the handle from a pasted url" do
      expect(@act.instagram).to eq("amylsniffers")
    end

    it "keeps a bare handle as it is" do
      @act.update!(instagram: "amylsniffers")

      expect(@act.instagram).to eq("amylsniffers")
    end

    it "clears the handle when given nil rather than raising" do
      @act.update!(instagram: nil)

      expect(@act.instagram).to be_nil
    end

    it "clears the bandcamp handle when given nil" do
      @act.update!(bandcamp: "https://amylandthesniffers.bandcamp.com")
      @act.update!(bandcamp: nil)

      expect(@act.bandcamp).to be_nil
    end

    it "treats a nil genre list as no genres" do
      @act.genre_list = nil

      expect(@act.genres).to eq([])
    end
  end
end
