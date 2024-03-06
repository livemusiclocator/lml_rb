module Lml
  class Gig < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      %w[name]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    enum :status, { draft: "draft", confirmed:"confirmed", cancelled: "cancelled"}, prefix: true

    belongs_to :venue
    belongs_to :headline_act, class_name: "Lml::Act"
    has_many :sets
    scope :filter_by_status, -> (status) { where(status: status) }
    scope :upcoming  , ->(days:3 ) {  Lml::Gig.where(start_time: (1.hour.ago...days.days.from_now)) }
  end


end
