# frozen_string_literal: true

require "rails_helper"

describe Lml::ApiToken do
  describe "issuing" do
    before do
      @user = create(:lml_user, :admin)
      @token = described_class.issue!(user: @user, name: "Import script")
    end

    it "hands back the secret exactly once" do
      expect(@token.plaintext).to start_with("lml_admin_")
      expect(described_class.find(@token.id).plaintext).to be_nil
    end

    it "never stores the secret" do
      expect(described_class.where(token_digest: @token.plaintext)).to be_empty
      expect(@token.token_digest).to eq(described_class.digest(@token.plaintext))
    end

    it "issues a different secret every time" do
      other = described_class.issue!(user: @user, name: "Something else")

      expect(other.plaintext).not_to eq(@token.plaintext)
    end
  end

  describe "authenticating" do
    before do
      @user = create(:lml_user, :admin)
      @token = described_class.issue!(user: @user, name: "Import script")
      @secret = @token.plaintext
    end

    it "recognises a token we issued" do
      expect(described_class.authenticate(@secret)).to eq(@token)
    end

    it "refuses a secret we never issued" do
      expect(described_class.authenticate("lml_admin_guessed")).to be_nil
    end

    it "refuses a blank secret, whatever the digest of an empty string might match" do
      expect(described_class.authenticate("")).to be_nil
      expect(described_class.authenticate(nil)).to be_nil
    end

    it "refuses a revoked token" do
      @token.revoke!

      expect(described_class.authenticate(@secret)).to be_nil
    end

    it "refuses an expired token" do
      @token.update!(expires_at: 1.minute.ago)

      expect(described_class.authenticate(@secret)).to be_nil
    end

    it "accepts a token whose expiry is still ahead of it" do
      @token.update!(expires_at: 1.day.from_now)

      expect(described_class.authenticate(@secret)).to eq(@token)
    end
  end

  describe "state" do
    before { @token = create(:lml_api_token) }

    it "is active with no expiry and no revocation" do
      expect(@token).to be_active
    end

    it "is not active once revoked" do
      @token.revoke!

      expect(@token).not_to be_active
    end

    it "keeps the first revocation time if revoked twice" do
      @token.revoke!
      revoked_at = @token.revoked_at
      @token.revoke!

      expect(@token.reload.revoked_at).to be_within(1.second).of(revoked_at)
    end

    it "records use without touching updated_at" do
      updated_at = @token.updated_at
      @token.record_use!

      expect(@token.reload.last_used_at).to be_present
      expect(@token.updated_at).to eq(updated_at)
    end
  end
end
