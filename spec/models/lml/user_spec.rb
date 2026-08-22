# frozen_string_literal: true

require "rails_helper"

describe Lml::User do
  describe "admin" do
    before do
      @admin = create(:lml_user, :admin)
      @punter = create(:lml_user)
    end

    it "is not an admin by default, so a new registration gets nothing" do
      expect(described_class.new.admin?).to be(false)
      expect(@punter.admin?).to be(false)
    end

    it "knows which users are admins" do
      expect(@admin.admin?).to be(true)
      expect(described_class.admins).to contain_exactly(@admin)
    end
  end
end
