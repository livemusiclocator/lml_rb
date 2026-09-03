# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpaAssets do
  let(:configured) { Rails.application.config.spa_assets }
  let(:base_url) { configured["entrypoint_script"].sub(%r{/[^/]+\z}, "") }
  let(:manifest_url) { "#{base_url}/manifest.json" }

  let(:manifest) do
    {
      "index.html" => {
        "file" => "lml_gig_explorer.abc123.js",
        "isEntry" => true,
        "src" => "index.html",
        "css" => ["lml_gig_explorer.def456.css"],
      },
    }
  end

  let(:hashed_assets) do
    {
      "entrypoint_script" => "#{base_url}/lml_gig_explorer.abc123.js",
      "css_files" => ["#{base_url}/lml_gig_explorer.def456.css"],
      "external_dependencies" => [],
    }
  end

  before { described_class.reset! }
  after { described_class.reset! }

  # the guard that keeps every other spec off the network
  describe "in the test environment" do
    it "uses the checked in config" do
      expect(described_class.current).to eq(configured)
    end

    it "does not ask for a manifest" do
      described_class.current

      expect(a_request(:get, manifest_url)).not_to have_been_made
    end
  end

  context "when it is allowed to read the manifest" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    it "builds the asset urls from the manifest, so a frontend deploy needs no rails deploy" do
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_json)

      expect(described_class.current).to eq(hashed_assets)
    end

    it "picks up other entry chunks the same way rake spa:fetch does" do
      manifest["src/worker.js"] = { "file" => "worker.xyz789.js", "isEntry" => true, "src" => "src/worker.js" }
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_json)

      expect(described_class.current["external_dependencies"]).to eq(["#{base_url}/worker.xyz789.js"])
    end

    it "only asks once inside the refresh window" do
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_json)

      3.times { described_class.current }

      expect(a_request(:get, manifest_url)).to have_been_made.once
    end

    it "asks again once the refresh window has passed" do
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_json)

      described_class.current
      travel(described_class::REFRESH_AFTER + 1.second) { described_class.current }

      expect(a_request(:get, manifest_url)).to have_been_made.twice
    end

    # everything below is a way the manifest can let us down. None of them may
    # take a page down: the last good answer stands, ultimately the checked in
    # config.
    it "falls back to the checked in config when the manifest cannot be reached" do
      stub_request(:get, manifest_url).to_timeout

      expect(described_class.current).to eq(configured)
    end

    it "falls back when the manifest is not there" do
      stub_request(:get, manifest_url).to_return(status: 404, body: "")

      expect(described_class.current).to eq(configured)
    end

    it "falls back when the manifest is not json" do
      stub_request(:get, manifest_url).to_return(status: 200, body: "<html>nope</html>")

      expect(described_class.current).to eq(configured)
    end

    it "falls back when the manifest has no entrypoint" do
      stub_request(:get, manifest_url).to_return(status: 200, body: { "src/other.js" => {} }.to_json)

      expect(described_class.current).to eq(configured)
    end

    it "keeps serving the last good answer when a later fetch fails" do
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_json)
      described_class.current
      stub_request(:get, manifest_url).to_timeout

      travel(described_class::REFRESH_AFTER + 1.second) { expect(described_class.current).to eq(hashed_assets) }
    end

    it "does not retry a failing manifest on every request" do
      stub_request(:get, manifest_url).to_timeout

      3.times { described_class.current }

      expect(a_request(:get, manifest_url)).to have_been_made.once
    end
  end
end
