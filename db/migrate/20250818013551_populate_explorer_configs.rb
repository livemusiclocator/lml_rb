# frozen_string_literal: true

class PopulateExplorerConfigs < ActiveRecord::Migration[7.0]
  def up
    configs_data = {
      "main" => {
        "default_location" => "anywhere",
        "selectable_locations" => %w[melbourne stkilda],
        "allow_all_locations" => true,
      },
      "geelong" => {
        "default_location" => "geelong",
        "selectable_locations" => ["geelong"],
        "allow_all_locations" => false,
      },
      "stkilda" => {
        "default_location" => "stkilda",
        "selectable_locations" => ["stkilda"],
        "allow_all_locations" => false,
        "series_themes" => [
          {
            "series_name" => "stkildaFestival2025",
            "search_result" => "gigSeriesCustom/stk_logo.svg",
            "saved_map_pin" => "mapPins/festival-pin-saved.png",
            "default_map_pin" => "mapPins/festival-pin.png",
          },
        ],
      },
    }

    # Create configs from the data
    configs_data.each do |key, hash|
      config = Web::ExplorerConfig.create!(
        edition_id: key,
        default_location: hash["default_location"],
        selectable_locations: hash["selectable_locations"] || [],
        allow_all_locations: hash["allow_all_locations"] || false,
      )
      next unless hash["series_themes"].present?

      hash["series_themes"].each do |theme_hash|
        config.series_themes.create!(
          series_name: theme_hash["series_name"],
          search_result: theme_hash["search_result"],
          saved_map_pin: theme_hash["saved_map_pin"],
          default_map_pin: theme_hash["default_map_pin"],
        )
      end
    end
  end

  def down
    puts "Not reverting explorer configs"
  end
end
