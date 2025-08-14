# frozen_string_literal: true

class CreateSeriesThemes < ActiveRecord::Migration[8.0]
  def change
    create_table :series_themes, id: :uuid do |t|
      t.references :explorer_config, null: false, foreign_key: true, type: :uuid
      t.string :series_name
      t.string :search_result
      t.string :saved_map_pin
      t.string :default_map_pin

      t.timestamps
    end
  end
end
