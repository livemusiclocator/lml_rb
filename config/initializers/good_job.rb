# frozen_string_literal: true

Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception) }
  config.good_job.execution_mode = :external
  config.good_job.queues = "*"
  config.good_job.max_threads = 2
  config.good_job.poll_interval = 30
end
