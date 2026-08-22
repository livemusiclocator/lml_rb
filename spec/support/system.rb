# frozen_string_literal: true

require "capybara/rspec"
require "capybara/cuprite"

# HEADED=1 puts a real Chrome window on screen; SLOWMO=0.5 spaces the actions out
# far enough to watch; `page.driver.pause` then breaks into it. All off by default
# so a plain `rspec` stays headless.
headed = ENV["HEADED"].present?

# Passed through driven_by rather than a register_driver block, because Rails lists
# :cuprite as one of the drivers it registers itself: driven_by re-registers the
# name on every example and a block of our own would simply be overwritten.
cuprite_options = {
  headless: !headed,
  inspector: headed,
  slowmo: ENV["SLOWMO"]&.to_f,
  process_timeout: 20,
  timeout: 15,
  # Chrome's sandbox needs privileges a CI container does not hand out.
  browser_options: ENV["CI"] ? { "no-sandbox" => nil, "disable-dev-shm-usage" => nil } : {},
}.compact

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

# Backstage lives behind `constraints subdomain: /^(beta|www).livemusiclocator/`,
# so a spec for it has to arrive on a matching host. Rails reads "www.livemusiclocator"
# as the subdomain of this one. Assign Capybara.app_host in the spec that needs it.
BACKSTAGE_APP_HOST = "http://www.livemusiclocator.com.localhost"
SYSTEM_SPEC_HOSTS = ["api.lml.localhost", "www.livemusiclocator.com.localhost"].freeze
Capybara.always_include_port = true

# Long enough to cover the pickers' 250ms input debounce plus the round trip.
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  # rails_helper requires webmock/rspec, which blocks every outbound connection
  # including Capybara's own server handshake. Let localhost through for system
  # specs only, so everything else keeps failing loudly on an unstubbed call.
  config.around(:each, type: :system) do |example|
    WebMock.disable_net_connect!(allow_localhost: true, allow: SYSTEM_SPEC_HOSTS)
    example.run
  ensure
    WebMock.disable_net_connect!
  end

  config.before(:each, type: :system) do
    driven_by :cuprite, screen_size: [1400, 1400], options: cuprite_options
  end
end
