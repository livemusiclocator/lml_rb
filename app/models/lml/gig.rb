module Lml
  class Gig < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[name headline_act_id venue_id]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[headline_act venue]
    end

    enum :status, { draft: "draft", confirmed: "confirmed", cancelled: "cancelled" }, prefix: true

    belongs_to :venue, optional: true
    belongs_to :headline_act, class_name: "Lml::Act", optional: true
    has_many :sets
    scope :eager, -> { order(start_time: :desc).includes(sets: :act).includes(:venue).includes(:headline_act) }
    scope :upcoming, ->(days: 3) { where(start_time: (1.hour.ago...days.days.from_now)) }
    scope :filter_by_date, ->(range_or_date) { where(date: range_or_date) }

    def label
      "#{name} (#{date})"
    end

    def venue_label
      venue&.label
    end

    def headline_act_label
      headline_act&.label
    end

    def tag_list
      (tags || []).join(", ")
    end

    def tag_list=(value)
      self.tags = value.split(",").map(&:strip)
    end
  end
end
