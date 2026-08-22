# frozen_string_literal: true

class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :token_digest, null: false
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.timestamps null: false
    end

    add_index :api_tokens, :token_digest, unique: true
  end
end
