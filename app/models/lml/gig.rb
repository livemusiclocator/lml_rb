module Lml
  class Gig < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[name headline_act_id venue_id checked date status created_at updated_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[headline_act venue]
    end

    def self.find_or_create_gig(name:, date:, venue:, details: {})
      gig = Lml::Gig.where(date: date, venue: venue).where("lower(name) = ?", name.downcase).first
      gig ||= Lml::Gig.create!(
        name: name,
        date: date,
        venue: venue,
      )
      gig.update!(details) unless details.empty?
      gig
    end

    enum :status, { draft: "draft", confirmed: "confirmed", cancelled: "cancelled" }, prefix: true
    belongs_to :venue, optional: true
    belongs_to :headline_act, class_name: "Lml::Act", optional: true
    has_many :sets
    has_many :prices

    accepts_nested_attributes_for :prices, :allow_destroy => true
    accepts_nested_attributes_for :sets, :allow_destroy => true
    scope :eager, -> { order(start_time: :desc).includes(sets: :act).includes(:venue).includes(:headline_act).includes(:prices) }
    scope :visible, -> { where(hidden: [nil, false]).where.not(status: "draft") }

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

    def start_offset_time=(value)
      self.start_offset = nil

      return unless value

      hours, mins = value.split(":").map(&:to_i)
      self.start_offset = (hours * 60) + mins
    end

    def start_offset_time
      return nil unless start_offset

      hours = start_offset / 60
      mins = start_offset % 60
      "#{format("%02d", hours)}:#{format("%02d", mins)}"
    end

    def start_at
      return unless date && start_offset && venue&.time_zone

      date.in_time_zone(venue.time_zone) + (start_offset / 1_440.0).days
    end
  end
end
