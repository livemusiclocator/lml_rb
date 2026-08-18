# frozen_string_literal: true

require "capybara/rspec"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 1400],
    headless: true,
    process_timeout: 20,
    timeout: 15,
    # Chrome's sandbox needs privileges a CI container does not hand out.
    browser_options: ENV["CI"] ? { "no-sandbox" => nil, "disable-dev-shm-usage" => nil } : {},
  )
end

# ActiveAdmin is mounted inside `constraints subdomain: /^api$/`, so the browser
# has to arrive on a host Rails can read a subdomain from - 127.0.0.1 has none,
# and "api.localhost" has too few parts for Rails to find one in either, so
# nothing under /admin would route.
#
# Deliberately not development's api.lml.test: keeping the two apart means a spec
# can never talk to a running development server, and it is obvious from a URL in
# a failure screenshot which one you are looking at.
Capybara.server_host = "127.0.0.1"
Capybara.app_host = "http://api.lml.localhost"
Capybara.always_include_port = true

# Long enough to cover the pickers' 250ms input debounce plus the round trip.
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  # rails_helper requires webmock/rspec, which blocks every outbound connection
  # including Capybara's own server handshake. Let localhost through for system
  # specs only, so everything else keeps failing loudly on an unstubbed call.
  config.around(:each, type: :system) do |example|
    WebMock.disable_net_connect!(allow_localhost: true, allow: ["api.lml.localhost"])
    example.run
  ensure
    WebMock.disable_net_connect!
  end

  config.before(:each, type: :system) do
    driven_by :cuprite
  end
end
