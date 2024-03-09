module Lml
  class Gig < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      %w[name]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    enum :status, { draft: "draft", confirmed: "confirmed", cancelled: "cancelled" }, prefix: true

    belongs_to :venue
    belongs_to :headline_act, class_name: "Lml::Act"
    has_many :sets
    default_scope { order(start_time: :desc).includes(sets: :act).includes(:venue).includes(:headline_act) }
    scope :upcoming , ->(days:3) {  where(start_time: (1.hour.ago...days.days.from_now)) }
    scope :filter_by_date, ->(range_or_date)  {  where(date: range_or_date) }
  end
end
