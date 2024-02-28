module Lml
  class Set < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      []
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    belongs_to :gig
    belongs_to :act
  end
end
