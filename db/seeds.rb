# frozen_string_literal: true

if Rails.env.development?
  user = AdminUser.find_or_create_by(email: "admin@example.com")
  user.update!(
    time_zone: ENV.fetch("TIMEZONE", "Australia/Melbourne"),
    password: "password",
  )
end
