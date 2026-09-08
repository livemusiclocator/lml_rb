# frozen_string_literal: true

require "rails_helper"

# `match "*path", to: "errors#not_found", via: :all` catches everything the gig guide does not
# route, which in practice is mostly scanner traffic - /wp/wp/v2/posts/999999 and the like. Those
# arrive with whatever Accept header they feel like, so the handler has to answer all of them
# rather than raising UnknownFormat and turning one unroutable request into two log backtraces.
describe "an unroutable path on the gig guide" do
  before do
    host! "www.livemusiclocator.com.au"
  end

  it "renders the 404 page for a browser" do
    get "/no/such/page"

    expect(response).to have_http_status(:not_found)
    expect(response.content_type).to include("text/html")
  end

  it "answers json with a bare 404" do
    get "/no/such/page", headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:not_found)
  end

  # The case that used to raise. An Accept header matching neither html nor json matched no
  # respond_to block at all.
  it "answers a nonsense accept header with a 404 rather than a 406" do
    get "/wp/wp/v2/posts/999999", headers: { "Accept" => "application/vnd.nonsense+xml" }

    expect(response).to have_http_status(:not_found)
  end

  it "answers a request with no accept header at all" do
    get "/wp-login.php", headers: { "Accept" => "" }

    expect(response).to have_http_status(:not_found)
  end

  # The route is via: :all, so the probes that POST get here too.
  it "answers a POST to an unroutable path" do
    post "/wp-login.php", headers: { "Accept" => "*/*" }

    expect(response).to have_http_status(:not_found)
  end
end
