# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

EventStatus.create!(name: "Confirmed") unless EventStatus.where(name: "Confirmed").exists?
EventStatus.create!(name: "Cancelled") unless EventStatus.where(name: "Cancelled").exists?

if Rails.env.development?
  AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') unless AdminUser.where(email: "admin@example.com").exists?
end
