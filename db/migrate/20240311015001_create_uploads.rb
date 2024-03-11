# frozen_string_literal: true

class CreateUploads < ActiveRecord::Migration[7.1]
  def change
    create_table :uploads, id: :uuid do |t|
      t.string :format
      t.text :content
      t.string :source

      t.timestamps
    end
  end
end
