# frozen_string_literal: true

# Nothing happens without SENTRY_DSN, which is only set on heroku. Sentry.init is what installs the
# exception handlers, so skipping it leaves development and CI exactly as they were - no network
# calls, no events, no accidental reporting of a spec that was meant to raise.
return if ENV["SENTRY_DSN"].blank?

Sentry.init do |config|
  config.dsn = ENV.fetch("SENTRY_DSN")

  # Which deploy an error came from. Heroku exposes this only if the dyno metadata labs feature is
  # enabled; without it the release is simply unset rather than wrong.
  config.release = ENV.fetch("HEROKU_SLUG_COMMIT", nil)
  config.environment = Rails.env

  # Breadcrumbs are the trail leading up to an error. active_support_logger picks up what Rails
  # logged; without it a backtrace arrives with no context about the request that caused it.
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # The one that matters for privacy. With this false, sentry attaches no request to an event at
  # all - no params, no query string, no cookies, no ip - so there is nothing to scrub. Verified
  # rather than assumed: an exception captured inside a real request carrying ?password=... arrives
  # with request nil. Turning it on would mean revisiting that, since a report would then carry
  # whatever was posted to /backstage/login.
  config.send_default_pii = false

  # No performance tracing. It is a separate quota on the free plan and this app has no latency
  # question worth spending it on yet.
  config.traces_sample_rate = 0.0
end
