# frozen_string_literal: true

module Lml
  class Set < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[act_id]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    def self.create_for_gig_from_line!(gig, line)
      act_name, start_offset_time, duration, stage = line.split("|").map(&:strip)
      return if act_name.blank?

      act = Lml::Act.find_or_create_act_from_line!(act_name)
      Lml::Set.create!(
        gig: gig,
        act: act,
        start_offset_time: start_offset_time,
        duration: duration,
        stage: stage,
      )
    end

    belongs_to :gig
    belongs_to :act

    def line
      act_description = act.name
      if act.location
        act_description = if act.country
                            "#{act_description} (#{act.location}/#{act.country})"
                          else
                            "#{act_description} (#{act.location}/Australia)"
                          end
      end
      "#{act_description} | #{start_offset_time} | #{duration} | #{stage}"
    end

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

    def start_timestamp
      return unless gig&.date && gig&.venue&.time_zone && start_offset

      gig.date.in_time_zone(gig.venue.time_zone) + (start_offset / 1_440.0).days
    end

    def finish_timestamp
      return unless gig&.date && gig&.venue&.time_zone && start_offset && duration

      gig.date.in_time_zone(gig.venue.time_zone) + ((start_offset + duration) / 1_440.0).days
    end
  end
end
