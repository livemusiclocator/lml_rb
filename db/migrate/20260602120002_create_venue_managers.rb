# frozen_string_literal: true

class CreateVenueManagers < ActiveRecord::Migration[8.1]
  def change
    create_table :venue_managers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :venue, null: false, foreign_key: { to_table: :venues }, type: :uuid
      t.timestamps null: false
    end

    add_index :venue_managers, [:user_id, :venue_id], unique: true
  end
end
