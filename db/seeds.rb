# frozen_string_literal: true

EventStatus.create!(name: "Confirmed") unless EventStatus.where(name: "Confirmed").exists?
EventStatus.create!(name: "Cancelled") unless EventStatus.where(name: "Cancelled").exists?

mogwai = Artist.find_or_create_by(name: "Mogwai")
mogwai.update!(
  location: "Glasgow",
  country: "Scotland",
  genres: %w["Post-Rock Electronic Film-Score Television-Music Ambient],
)
jerm = Artist.find_or_create_by(name: "Jerm")
jerm.update!(
  location: "Brisbane",
  country: "Australia",
  genres: %w[Electronic Darkwave],
)

tivoli = Venue.find_or_create_by(name: "The Tivoli")
tivoli.update!(
  address: "52 Costin St, Fortitude Valley, Brisbane",
  latitude: "-27.452117",
  longitude: "153.028929",
  location_url: "https://maps.app.goo.gl/tWw3Waee4ic48EAd8",
)

if Rails.env.development? && !AdminUser.where(email: "admin@example.com").exists?
  AdminUser.create!(
    email: "admin@example.com",
    password: "password",
    password_confirmation: "password",
  )
end
