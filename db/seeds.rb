# frozen_string_literal: true

confirmed = Lml::Status.find_or_create_by!(name: "Confirmed")
Lml::Status.find_or_create_by!(name: "Cancelled")

mogwai = Lml::Act.find_or_create_by(name: "Mogwai")
mogwai.update!(
  location: "Glasgow",
  country: "Scotland",
  genres: %w[Post-Rock Electronic Film-Score Television-Music Ambient],
)
jerm = Lml::Act.find_or_create_by(name: "Jerm")
jerm.update!(
  location: "Brisbane",
  country: "Australia",
  genres: %w[Electronic Darkwave],
)

tivoli = Lml::Venue.find_or_create_by(name: "The Tivoli")
tivoli.update!(
  address: "52 Costin St, Fortitude Valley, Brisbane",
  latitude: "-27.452117",
  longitude: "153.028929",
  location_url: "https://maps.app.goo.gl/tWw3Waee4ic48EAd8",
)

mogwai_at_tiv = Lml::Gig.find_or_create_by(name: "Mogwai at The Tivoli 2024")
mogwai_at_tiv.update!(
  venue: tivoli,
  headline_act: mogwai,
  status: confirmed,
  date: "2024-02-21",
  start_time: "2024-02-21 19:30+10",
  finish_time: "2024-02-21 22:30+10",
)

mogwai_at_tiv_jerm = Lml::Set.find_or_create_by(gig: mogwai_at_tiv, act: jerm)
mogwai_at_tiv_jerm.update!(
  start_time: "2024-02-21 20:00+10",
  finish_time: "2024-02-21 21:00+10",
)
mogwai_at_tiv_mogwai = Lml::Set.find_or_create_by(gig: mogwai_at_tiv, act: mogwai)
mogwai_at_tiv_mogwai.update!(
  start_time: "2024-02-21 21:30+10",
  finish_time: "2024-02-21 22:30+10",
)

if Rails.env.development?
  user = AdminUser.find_or_create_by(email: "admin@example.com")
  user.update!(
    time_zone: ENV.fetch("TIMEZONE", "Melbourne"),
    password: "password",
  )
end
