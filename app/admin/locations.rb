# frozen_string_literal: true

ActiveAdmin.register Lml::Location, as: "Location" do
  # Permitted parameters - add the new fields
  permit_params :internal_identifier, :name, :latitude, :longitude,
                :seo_title_format_string, :map_zoom_level,
                visible_in_editions: []

  # Index page configuration
  index do
    selectable_column
    id_column
    column :internal_identifier
    column :name
    column :latitude
    column :longitude
    column :map_zoom_level
    column "Venues Count" do |location|
      location.venues.count
    end
    column "Editions" do |location|
      location.visible_in_editions&.join(", ") if location.visible_in_editions.present?
    end
    column :created_at
    actions
  end

  # Show page configuration
  show do
    attributes_table do
      row :id
      row :internal_identifier
      row :name
      row :latitude
      row :longitude
      row :map_zoom_level
      row :seo_title_format_string
      row "Visible in Editions" do |location|
        location.visible_in_editions&.join(", ") if location.visible_in_editions.present?
      end
      row :created_at
      row :updated_at
    end
    panel "Associated Venues" do
      if resource.venues.any?
        table_for resource.venues do |_table|
          column :link do |venue|
            link_to venue.name, admin_venue_path(venue)
          end
          column :gig_count do |venue|
            venue.gigs.length
          end
          # Add other venue columns as needed
          column :created_at
        end
      else
        div "No venues found for this location"
      end
    end
  end

  # Form configuration
  form do |f|
    f.inputs "Basic Information" do
      f.input :internal_identifier
      f.input :name
      f.input :latitude, step: :any
      f.input :longitude, step: :any
    end

    f.inputs "Display Settings" do
      f.input :visible_in_editions,
              as: :check_boxes,
              collection: Lml::Location::AVAILABLE_EDITIONS,
              hint: "Select which editions this location should be visible in",
              include_hidden: false, include_blank: false
      f.input :map_zoom_level,
              hint: "Zoom level for maps (1-20, default: 15)"
      f.input :seo_title_format_string,
              hint: "Optional format string for SEO page titles"
    end

    f.actions
  end

  # Filters
  filter :internal_identifier
  filter :name
  filter :latitude
  filter :longitude
  filter :map_zoom_level
  filter :seo_title_format_string
  filter :created_at
  filter :updated_at
end
