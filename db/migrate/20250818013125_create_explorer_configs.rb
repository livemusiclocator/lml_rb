# frozen_string_literal: true

class CreateExplorerConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :explorer_configs, id: :uuid do |t|
      t.string :edition_id
      t.boolean :allow_all_locations
      t.text :selectable_locations
      t.string :default_location
      t.timestamps
    end
  end
end
