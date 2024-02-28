class AddActToSets < ActiveRecord::Migration[7.1]
  def change
    add_reference :sets, :act, type: :uuid, foreign_key: true
  end
end
