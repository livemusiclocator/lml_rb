# frozen_string_literal: true

class AddInitialLmlTourismRegions < ActiveRecord::Migration[8.1]
  def up
    tourism_regions = [
      { internal_identifier: "melbourne", name: "Melbourne" },
      { internal_identifier: "geelong_bellarine", name: "Geelong & the Bellarine" },
      { internal_identifier: "goldfields", name: "Goldfields" },
      { internal_identifier: "great_ocean_road", name: "Great Ocean Road" },
      { internal_identifier: "high_country", name: "High Country" },
      { internal_identifier: "murray", name: "The Murray" },
      { internal_identifier: "grampians", name: "Grampians" },
      { internal_identifier: "gippsland", name: "Gippsland" },
      { internal_identifier: "phillip_island", name: "Phillip Island" },
      { internal_identifier: "daylesford_macedon_ranges", name: "Daylesford and the Macedon Ranges" },
      { internal_identifier: "mornington_peninsula", name: "Mornington Peninsula" },
      { internal_identifier: "yarra_valley_dandenong_ranges", name: "Yarra Valley & Dandenong Ranges" },
    ]

    tourism_regions.each do |attrs|
      Web::TourismRegion.find_or_create_by(internal_identifier: attrs[:internal_identifier]) do |tourism_region|
        tourism_region.assign_attributes(attrs)
      end
    end

    puts "Added #{tourism_regions.count} initial tourism_regions"
  end

  def down
    identifiers_to_remove = %w[
      melbourne
      geelong_bellarine
      goldfields
      great_ocean_road
      high_country
      murray
      grampians
      gippsland
      phillip_island
      daylesford_macedon_ranges
      mornington_peninsula
      yarra_valey_dandenong_ranges
    ]

    removed_count = Web::TourismRegion.where(internal_identifier: identifiers_to_remove).delete_all
    puts "Removed #{removed_count} initial tourism_regions"
  end
end
