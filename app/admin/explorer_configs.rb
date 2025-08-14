# frozen_string_literal: true

# app/admin/web/explorer_configs.rb
ActiveAdmin.register Web::ExplorerConfig, as: "Explorer Config" do
  menu parent: "Web App", priority: 1

  permit_params :edition_id, :allow_all_locations, :default_location,
                selectable_locations: [],
                series_themes_attributes: %i[id series_name search_result saved_map_pin default_map_pin _destroy]

  # Index page
  index do
    selectable_column
    id_column
    column :edition_id
    column :default_location do |config|
      location = Web::Location.find_by(internal_identifier: config.default_location)
      location ? "#{location.name} (#{config.default_location})" : config.default_location
    end
    column :allow_all_locations
    column :selectable_locations do |config|
      valid_locations = config.selectable_locations & Web::Location.pluck(:internal_identifier)
      valid_locations.map do |id|
        location = Web::Location.find_by(internal_identifier: id)
        location ? location.name : id
      end.join(", ")
    end
    column :series_themes do |config|
      config.series_themes.count
    end
    actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :edition_id
      row :default_location do |config|
        location = Web::Location.find_by(internal_identifier: config.default_location)
        if location
          "#{location.name} (#{config.default_location})"
        else
          config.default_location
        end
      end
      row :allow_all_locations
      row :selectable_locations do |config|
        valid_locations = config.selectable_locations & Web::Location.pluck(:internal_identifier)
        if valid_locations.present?
          ul do
            valid_locations.each do |id|
              location = Web::Location.find_by(internal_identifier: id)
              li location ? "#{location.name} (#{id})" : id
            end
          end
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Series Themes" do
      if resource.series_themes.any?
        table_for resource.series_themes do
          column :series_name
          column :search_result
          column :saved_map_pin
          column :default_map_pin
        end
      else
        div "No series themes configured"
      end
    end
  end

  # Form for creating/editing
  form do |f|
    unless f.object.new_record?

      div class: "flash flash_warning config-warning" do
        h3 "⚠️ Warning! "
        para do
          "Changes to this configuration will affect the live website immediately and could break stuff! Proceed with caution 😎... "
        end
      end
    end
    f.inputs "Basic Configuration" do
      f.input :edition_id if f.object.new_record?
      f.input :default_location,
              as: :select,
              collection: Web::Location.all.collect { |loc| [loc.name, loc.internal_identifier] },
              include_blank: "Select a location",
              hint: "Default location for this configuration"
      f.input :allow_all_locations,
              hint: "Allow locations not in the search criteria (via querystring parameter)"
    end

    f.inputs "Location Selection" do
      f.input :selectable_locations,
              as: :check_boxes,
              collection: Web::Location.all.collect { |loc| [loc.name, loc.internal_identifier] },
              hint: "Locations that can be selected (location filter is readonly if only one location is given)"
    end

    f.inputs "Series Themes" do
      f.has_many :series_themes,
                 heading: "Theme Configurations",
                 allow_destroy: true,
                 new_record: true do |theme_form|
        theme_form.input :series_name, hint: "Series name as appearing in the gig.series field"
        theme_form.input :search_result, hint: "image shown on gig pages when matching this series"
        theme_form.input :default_map_pin, hint: "map pin image for venue when has at least one gig in this series"
        theme_form.input :saved_map_pin,
                         hint: "map pin image for venue with saved 'star' when has at least one gig in this series"
      end
    end

    if f.object.new_record?
      f.actions
    else

      f.actions do
        f.action :submit, label: "Update Explorer Configuration",
                          button_html: { data: { confirm: "Are you sure you want to save these configuration changes? This will affect the live website immediately and might break stuff." } }
        f.action :cancel, label: "Cancel"
      end
    end
  end

  # Filters for the index page
  filter :edition_id
  filter :allow_all_locations
  filter :default_location, as: :select, collection: -> { Web::Location.pluck(:internal_identifier) }
  filter :created_at
  filter :updated_at
end
