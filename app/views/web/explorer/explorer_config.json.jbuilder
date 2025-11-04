# app/views/web/explorer_configs/show.json.jbuilder
json.defaultLocation @explorer_config.default_location
json.gigsEndpoint Rails.env.development? ? "https://api.lml.test/gigs" : "https://api.lml.live/gigs"
json.rootPath relative_path({ path_name: :web_root})
json.shuffleSeriesAssignments ["stkildaFestival2025", "nope", "nope", "nope"]
json.allowSelectLocation @explorer_config.locations.length>1
json.allLocations @explorer_config.locations do |location|
   json.id location.internal_identifier
   json.caption location.name
   json.mapCenter [location.latitude,location.longitude]
   json.zoom location.map_zoom_level
   json.selectable @explorer_config.selectable_locations.include?(location.internal_identifier)
end
json.themes do
  json.series do
    @explorer_config.series_themes.each do |series_theme|
      json.set! series_theme.series_name do
        json.searchResult series_theme.search_result
        json.savedMapPin series_theme.saved_map_pin
        json.defaultMapPin series_theme.default_map_pin
      end
    end
  end
end
