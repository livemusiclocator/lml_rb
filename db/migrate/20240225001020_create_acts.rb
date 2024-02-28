class CreateActs < ActiveRecord::Migration[7.1]
  def change
    create_table :acts, id: :uuid do |t|
      t.string :name
      t.string :country
      t.string :location
      t.jsonb :genres

      t.timestamps
    end
  end
end
