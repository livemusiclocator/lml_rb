module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[format source]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    validates :format, presence: true
    validates :source, presence: true
    validates :content, presence: true

    def process!
      return unless valid?

      details = {}

      content.lines.each do |line|
        key, *rest = line.chomp.strip.split(":")
        value = rest.join(":")
        key = key.downcase.gsub(" ", "_")
        case key
        when "act_name"
          details[:act_name] = value
        when "venue_name"
          details[:venue_name] = value
        when "gig_name"
          details[:gig_name] = value
        when "gig_date", "gig_start_date"
          details[:date] = Date.parse(value)
        when "gig_start_time"
          details[:time] = Time.parse(value)
        end
      end

      gig = Lml::Gig.find_or_create_by(name: details[:gig_name])
      append_act(gig, details[:act_name])
      append_venue(gig, details[:venue_name])
      append_date_time(gig, details[:date], details[:time])
      gig.save
    end

    private

    def append_act(gig, name)
      return unless name

      act = Lml::Act.find_or_create_by(name: name)
      gig.headline_act = act
      Lml::Set.find_or_create_by(gig: gig, act: act)
    end

    def append_venue(gig, name)
      return unless name

      gig.venue = Lml::Venue.find_or_create_by(name: name)
    end

    def append_date_time(gig, date, time)
      return unless date

      gig.date = date
      return unless time

      gig.start_time = "#{date.iso8601}T#{time.strftime("%H:%M")}:00"
    end
  end
 end
