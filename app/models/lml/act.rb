module Lml
  class Act < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      %w[name country location]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end
  end
end
