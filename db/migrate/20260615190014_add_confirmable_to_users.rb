# frozen_string_literal: true

class AddConfirmableToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true

    # Mark all existing users as already confirmed so they don't get locked out
    reversible do |dir|
      dir.up { execute "UPDATE users SET confirmed_at = NOW() WHERE confirmed_at IS NULL" }
    end
  end
end
