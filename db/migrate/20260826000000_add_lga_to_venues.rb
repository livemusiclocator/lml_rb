# frozen_string_literal: true

class AddLgaToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :lga, :string
  end
end
