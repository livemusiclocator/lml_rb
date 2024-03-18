# frozen_string_literal: true

require "rails_helper"

RSpec.describe FetchEventfindaJob, type: :job do
  let(:config) do
    { enabled: true,
      endpoint_url: "http://nope",
      max_pages: 10,
      query: {
        something: "here",
      },
      skip_category_slugs: ["not-cool"],
      credentials: { username: "user1", password: "batterystaplecorrect" }, }
  end
  before do
    allow(Rails.application).to receive(:config_for)
      .with(:eventfinda)
      .and_return(double("eventfinda_config", config))
  end
  describe :perform do
    before do
      stub_request(:get, /.*/).to_return_json(body: { events: [], :@attributes => { count: 0 } })
    end
    it "calls the eventfinda event endpoint", :aggregate_failures do
      FetchEventfindaJob.new.perform
      expect(a_request(:get, /.*/).with(basic_auth: %w[user1 batterystaplecorrect])).to have_been_made
      expect(a_request(:get,
                       "http://nope/v2/events.json",).with(query: hash_including(config[:query]))).to have_been_made
    end

    context "with invalid credentials" do
      before do
        stub_request(:get, /.*/).to_return(status: 401)
      end
      it "fails" do
        expect { FetchEventfindaJob.new.perform }.to raise_error Faraday::UnauthorizedError
      end
    end
    context "single page of data in response" do
      it "converts the events to schema.org format", :aggregate_failures do
        stub_request(:get,
                     /.*/,).to_return_json(body: { events: [{ name: "E1" }, { name: "E2" }],
                                                   :@attributes => { count: 2 }, })
        expect do
          FetchEventfindaJob.new.perform
        end.to change(Lml::Upload, :count).by(1)

        upload = Lml::Upload.order("created_at").last
        expect(upload).to have_attributes(source: "eventfinda_com_au", format: "schema_org_events")
        # TODO: test this better? schema-org specific expectations if we wind up using a lot?
        result = JSON.parse(upload.content, object_class: OpenStruct)
        expect(result.length).to eq(2)
        expect(result[0]).to have_attributes(name: "E1", :@type => "MusicEvent")
        expect(result[1]).to have_attributes(name: "E2", :@type => "MusicEvent")
        expect(a_request(:get, /.*/)).to have_been_made.once
      end
    end
    context "multiple pages of data in response" do
      it "fetches offsets of data until the provided count has been met" do
        stub_request(:get, %r{http://nope}).to_return_json(body: { events: [{}, {}], :@attributes => { count: 6 } })
        FetchEventfindaJob.new.perform
        expect(a_request(:get, /.*/)).to have_been_made.times(3)
        expect(a_request(:get, /.*/).with(query: hash_including(offset: "2"))).to have_been_made
        expect(a_request(:get, /.*/).with(query: hash_including(offset: "4"))).to have_been_made
      end
    end
    context "encounters an empty page" do
      it "stops fetching data regardless of count" do
        stub_request(:get,
                     /.*/,).with(query: hash_excluding(:offset)).to_return_json(body: { events: [{}, {}],
                                                                                        :@attributes => { count: 4 }, })
        stub_request(:get,
                     /.*/,).with(query: hash_including(offset: "2")).to_return_json(body: { events: [],
                                                                                            :@attributes => { count: 4 }, })
        FetchEventfindaJob.new.perform
        expect(a_request(:get, /.*/)).to have_been_made.times(2)
      end
    end

    context "reaches maximum request limit without completing dataset" do
      it "stops fetching data regardless of count" do
        stub_request(:get, /.*/).to_return_json(body: { events: [{}, {}], :@attributes => { count: 4000 } })
        FetchEventfindaJob.new.perform
        expect(a_request(:get, /.*/)).to have_been_made.times(10)
      end
    end
    context "events from excluded category_slug in response" do
      it "does not persist excluded categories" do
        stub_request(:get,
                     /.*/,).with(query: hash_excluding(:offset)).to_return_json(body: { events: [{ category: { url_slug: "not-cool" } }, {}],
                                                                                        :@attributes => { count: 2 }, })
        FetchEventfindaJob.new.perform

        upload = Lml::Upload.order("created_at").last
        result = JSON.parse(upload.content)
        expect(result.length).to eq(1)
      end
    end
  end
end
