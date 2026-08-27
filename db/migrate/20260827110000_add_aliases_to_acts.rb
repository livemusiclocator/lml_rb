# frozen_string_literal: true

class AddAliasesToActs < ActiveRecord::Migration[8.1]
  def change
    add_column :acts, :aliases, :jsonb
  end
end
