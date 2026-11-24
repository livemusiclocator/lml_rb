# frozen_string_literal: true

class CreateTourismRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :tourism_regions, id: :uuid do |t|
      t.string :name, null: false
      t.string :internal_identifier, null: false

      t.timestamps
    end
    add_index :tourism_regions, :internal_identifier, unique: true
  end
end
