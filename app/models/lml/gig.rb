module Lml
  class Gig < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      %w[name]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    belongs_to :venue
    belongs_to :headline_act, class_name: "Lml::Act"
    belongs_to :status
  end
end
