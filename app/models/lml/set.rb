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

    def start_offset_time=(value)
      self.start_offset = nil

      return if value.blank?

      time = Time.parse(value)
      self.start_offset = (time.hour * 60) + time.min
    end

    def start_offset_time
      return nil unless start_offset

      hours = start_offset / 60
      mins = start_offset % 60
      "#{format("%02d", hours)}:#{format("%02d", mins)}"
    end

    def start_at
      return unless gig&.date && gig&.venue&.time_zone && start_offset

      gig.date.in_time_zone(gig.venue.time_zone) + start_offset.minutes
    end
  end
end
