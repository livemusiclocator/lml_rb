# frozen_string_literal: true

# or your Rails version
class AddFieldsToLmlLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :locations, :seo_title_format_string, :string
    add_column :locations, :map_zoom_level, :integer, null: false, default: 15
    add_column :locations, :visible_in_editions, :json, default: []
  end
end
