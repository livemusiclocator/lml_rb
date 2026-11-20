# frozen_string_literal: true

require "rails_helper"

describe "favicons" do
  it "ships a real favicon.ico rather than the empty rails placeholder" do
    %w[favicon.ico favicon.svg apple-touch-icon.png apple-touch-icon-precomposed.png apple-touch-icon-180x180.png].each do |name|
      expect(Rails.public_path.join(name).size).to be > 0, "#{name} is empty"
    end
  end

  it "links the icon from backstage" do
    host! "www.livemusiclocator.com.au"

    get "/backstage/login"

    expect(response.body).to include('<link rel="icon" href="/favicon.svg"')
  end

  it "links the icon from active admin" do
    host! "api.lml.live"

    get "/admin/login"

    expect(response.body).to match(/<link[^>]*rel="icon"[^>]*href="\/favicon.ico"|<link[^>]*href="\/favicon.ico"[^>]*rel="icon"/)
  end
end
