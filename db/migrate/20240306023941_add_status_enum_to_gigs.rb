# frozen_string_literal: true

class AddStatusEnumToGigs < ActiveRecord::Migration[7.1]
  def change
    create_enum :status, %w[draft confirmed cancelled]

    change_table :gigs do |t|
      t.enum :status, enum_type: "status", default: "draft", null: false
    end
  end
end
