# frozen_string_literal: true
require "rails_helper"

RSpec.describe FetchEventfindaJob, type: :job do
  let(:config) do
    { enabled: true,
      endpoint_url: "http://nope",
      page_size: 2,
      max_pages: 2,
      credentials: { username: "user1", password: "batterystaplecorrect" }, }
  end
  before do
    allow(Rails.application).to receive(:config_for)
      .with(:eventfinda)
      .and_return(double("eventfinda_config", config))
  end
  describe :perform do
    it "auths with basic auth" do
      stub_request(:get, %r{http://nope}).to_return_json(body: { events: [], :@attributes => { count: 0 } })
      FetchEventfindaJob.new.perform
      expect(a_request(:get, /.*/).with(basic_auth: %w[user1 batterystaplecorrect])).to have_been_made
    end

    describe "with invalid credentials" do
      before do
        stub_request(:get, /.*/).to_return(status: 401)
      end
      it "fails" do
        expect { FetchEventfindaJob.new.perform }.to raise_error Faraday::UnauthorizedError
      end
    end

    it "fetches multiple pages of results from the eventfinda api up to a maximum" do
      stub_request(:get, %r{http://nope}).to_return_json(body: { events: [{}, {}], :@attributes => { count: 6 } })
      FetchEventfindaJob.new.perform
      upload = Lml::Upload.filter_by_source("eventfinda_com_au").order(created_at: :desc).limit(1)
      content = JSON.parse(upload[0].content, symbolize_names: true)
      expect(content).to eq({ events: [{}, {}, {}, {}] })
      expect(upload[0].format).to eq("eventfinder_events")

      expect(a_request(:get, /.*/)).to have_been_made.times(2)
      expect(a_request(:get, /.*/).with(query: hash_including(offset: "0"))).to have_been_made
      expect(a_request(:get, /.*/).with(query: hash_including(offset: "2"))).to have_been_made
    end
  end
end
