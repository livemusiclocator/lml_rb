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
    has_many :sets
    scope :filter_by_status, -> (status) { joins(:status).where(status: {name: status}) }
    scope :confirmed, -> { filter_by_status("Confirmed") }
    scope :upcoming  , ->(days:3 ) {  Lml::Gig.where(start_time: (1.hour.ago...days.days.from_now)) }
  end


end
