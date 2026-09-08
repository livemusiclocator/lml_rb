# frozen_string_literal: true

require "rails_helper"

# config/initializers/sentry.rb returns early unless SENTRY_DSN is set, and the suite runs without
# one. If that guard is ever dropped, every spec that deliberately raises would start reporting
# itself as a production error, and it would not be obvious from a green run.
describe Sentry do
  it "leaves sentry uninitialised without a DSN" do
    expect(ENV.fetch("SENTRY_DSN", nil)).to be_blank
    expect(Sentry.initialized?).to be(false)
  end

  # Nothing calls this in the suite, but the whole point of the gem is that it is safe to reach for
  # from anywhere. Uninitialised, it has to be a no-op rather than an error of its own.
  it "makes capturing an exception a no-op rather than a failure" do
    expect { Sentry.capture_exception(RuntimeError.new("boom")) }.not_to raise_error
  end
end
