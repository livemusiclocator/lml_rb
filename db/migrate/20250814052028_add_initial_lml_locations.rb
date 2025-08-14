# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

class AddInitialLmlLocations < ActiveRecord::Migration[7.0]
  def up
    # Locations from frontend
    locations = [
      { internal_identifier: "anywhere", name: "Anywhere", latitude: -37.40725549559874, longitude: 143.90167236328128,
        map_zoom_level: 9, },
      { internal_identifier: "adelaide", name: "Adelaide", latitude: -34.9256018, longitude: 138.5801261,
        map_zoom_level: 15, },
      { internal_identifier: "brisbane", name: "Brisbane", latitude: -27.4704072, longitude: 153.012729,
        map_zoom_level: 15, },
      { internal_identifier: "castlemaine", name: "Castlemaine", latitude: -37.063670785361964,
        longitude: 144.21660007885495, map_zoom_level: 15, },
      { internal_identifier: "goldfields", name: "Goldfields", latitude: -37.063670785361964,
        longitude: 144.21660007885495, map_zoom_level: 10, },
      { internal_identifier: "melbourne", name: "Melbourne", latitude: -37.80198943476701,
        longitude: 144.9594068527222, map_zoom_level: 14, },
      { internal_identifier: "perth", name: "Perth", latitude: -31.95211262081573, longitude: 115.85813946429992,
        map_zoom_level: 15, },
      { internal_identifier: "sydney", name: "Sydney", latitude: -33.8695692, longitude: 151.1307609,
        map_zoom_level: 15, },
      { internal_identifier: "stkilda", name: "St Kilda", latitude: -37.8642383, longitude: 144.9613908,
        map_zoom_level: 15, },
      { internal_identifier: "geelong", name: "Geelong", latitude: -38.12908505319935, longitude: 144.25186157226565,
        map_zoom_level: 12, },
    ]

    locations.each do |location_attrs|
      Web::Location.find_or_create_by(internal_identifier: location_attrs["internal_identifier"]) do |location|
        location.assign_attributes(location_attrs)
      end
    end

    puts "Added #{locations.count} initial locations"
  end

  def down
    identifiers_to_remove = %w[anywhere adelaide brisbane castlemaine goldfields melbourne perth sydney stkilda geelong]

    removed_count = Web::Location.where(internal_identifier: identifiers_to_remove).delete_all
    puts "Removed #{removed_count} initial locations"
  end
end

# rubocop:enable Metrics/MethodLength
