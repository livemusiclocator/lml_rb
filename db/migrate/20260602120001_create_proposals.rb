# frozen_string_literal: true

class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :target_type
      t.uuid :target_id
      t.string :proposed_type
      t.jsonb :proposed_attributes, default: {}
      t.integer :status, default: 0, null: false
      t.text :note
      t.text :reviewer_note
      t.references :reviewed_by, foreign_key: { to_table: :admin_users }, type: :uuid
      t.datetime :reviewed_at
      t.timestamps null: false
    end

    add_index :proposals, [:target_type, :target_id]
    add_index :proposals, :status
  end
end
