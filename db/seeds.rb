# frozen_string_literal: true

if Rails.env.development?
  user = Lml::AdminUser.find_or_create_by(email: "admin@example.com")
  user.update!(
    time_zone: ENV.fetch("TIMEZONE", "Australia/Melbourne"),
    password: "password",
  )

  [
    ["anywhere", "Anywhere", -37.40725549559874, 143.90167236328128, 9],
    ["adelaide", "Adelaide", -34.9256018, 138.5801261, 15],
    ["brisbane", "Brisbane", -27.4704072, 153.012729, 15],
    ["castlemaine", "Castlemaine", -37.063670785361964, 144.21660007885495, 15],
    ["goldfields", "Goldfields", -37.063670785361964, 144.21660007885495, 10],
    ["melbourne", "Melbourne", -37.80198943476701, 144.9594068527222, 14],
    ["perth", "Perth", -31.95211262081573, 115.85813946429992, 15],
    ["sydney", "Sydney", -33.8695692, 151.1307609, 15],
    ["stkilda", "St Kilda", -37.8642383, 144.9613908, 15],
    ["geelong", "Geelong", -38.12908505319935, 144.25186157226565, 12],
    ["bendigo", "Bendigo", -36.760192398148355, 144.2293739318848, 13],
  ].each do |internal_identifier, name, latitude, longitude, map_zoom_level|
    location = Web::Location.find_by(internal_identifier: internal_identifier)
    location ||= Web::Location.create!(
      internal_identifier: internal_identifier,
      name: name,
      latitude: latitude,
      longitude: longitude,
      map_zoom_level: map_zoom_level,
    )
  end

  [
    ["geelong", false, ["geelong"], "geelong"],
    ["stkilda", false, ["stkilda"], "stkilda"],
    ["main", true, ["castlemaine", "melbourne", "stkilda", "geelong", "bendigo"], "anywhere"],
  ].each do |edition_id, allow_all_locations, selectable_locations, default_location|
    edition = Web::ExplorerConfig.find_by(edition_id: edition_id)
    edition ||= Web::ExplorerConfig.create!(
      edition_id: edition_id,
      allow_all_locations: allow_all_locations,
      selectable_locations: selectable_locations,
      default_location: default_location,
    )
  end

  ## Seed dummy venues for local tests
  # Venues
  venue1 = Lml::Venue.find_or_create_by!(name: "The Night Cat") do |v|
    v.address = "137-141 Johnston St, Fitzroy VIC 3065"
    v.location = "melbourne"
    v.time_zone = "Australia/Melbourne"
  end

  venue2 = Lml::Venue.find_or_create_by!(name: "The Tote") do |v|
    v.address = "67-71 Johnston St, Collingwood VIC 3066"
    v.location = "melbourne"
    v.time_zone = "Australia/Melbourne"
  end

  venue3 = Lml::Venue.find_or_create_by!(name: "Theatre Royal") do |v|
    v.address = "30 Hargraves St, Castlemaine VIC 3450"
    v.location = "castlemaine"
    v.time_zone = "Australia/Melbourne"
  end

  puts "Created #{Lml::Venue.count} venues."

  # Acts
  act1 = Lml::Act.find_or_create_by!(name: "The Teskey Brothers") do |a|
    a.country = "Australia"
    a.genres = ["Soul", "Blues"]
    a.email = "teskey@example.com"
  end

  act2 = Lml::Act.find_or_create_by!(name: "King Gizzard & The Lizard Wizard") do |a|
    a.country = "Australia"
    a.genres = ["Psychedelic Rock", "Garage Rock"]
    a.email = "gizz@example.com"
  end

  act3 = Lml::Act.find_or_create_by!(name: "Amyl and The Sniffers") do |a|
    a.country = "Australia"
    a.genres = ["Punk Rock"]
    a.email = "amyl@example.com"
  end

  act4 = Lml::Act.find_or_create_by!(name: "Khruangbin") do |a|
    a.country = "USA"
    a.genres = ["Thai Funk", "Psychedelic Soul"]
    a.email = "khruangbin@example.com"
  end

  act_test = Lml::Act.find_or_create_by!(name: "test_act") do |a|
    a.country = "Australia"
    a.genres = ["Test Genre"]
  end

  puts "Created #{Lml::Act.count} acts."

  # Seed a few upcoming gigs for testing
  # Gigs & Sets
  def create_gig_with_sets(name, venue, date, acts)
    gig = Lml::Gig.find_or_create_by!(name: name, venue: venue, date: date) do |g|
      g.status = "confirmed"
    end

    acts.each_with_index do |act, index|
      Lml::Set.find_or_create_by!(gig: gig, act: act) do |s|
        s.start_offset = index * 60
        s.duration = 45
      end
    end
    gig
  end

  today = Date.today

  create_gig_with_sets("Friday Night Soul", venue1, today + 7, [act1, act4])
  create_gig_with_sets("Gizz Fest", venue2, today + 14, [act2, act3])
  create_gig_with_sets("Sniffers Live", venue3, today + 21, [act3])
  create_gig_with_sets("Test Gig", venue1, today + 1, [act_test])
  create_gig_with_sets("Surprise Show", venue1, today - 2, [act2]) # Past gig

  puts "Created #{Lml::Gig.count} gigs."
  puts "Created #{Lml::Set.count} sets."

  puts "Dummy data insertion complete."
end
