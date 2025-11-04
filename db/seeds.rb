# frozen_string_literal: true

if Rails.env.development?
  user = AdminUser.find_or_create_by(email: "admin@example.com")
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
end
