class EventSet < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    []
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  belongs_to :event
  belongs_to :artist
end
