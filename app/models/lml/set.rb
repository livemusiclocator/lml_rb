module Lml
  class Set < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      %w[act_id]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    belongs_to :gig
    belongs_to :act

    def gig_label
      gig&.label
    end

    def act_label
      act&.label
    end
  end
end
