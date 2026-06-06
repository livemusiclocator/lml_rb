# frozen_string_literal: true

class CreateActManagers < ActiveRecord::Migration[8.1]
  def change
    create_table :act_managers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :act, null: false, foreign_key: { to_table: :acts }, type: :uuid
      t.timestamps null: false
    end

    add_index :act_managers, [:user_id, :act_id], unique: true
  end
end
