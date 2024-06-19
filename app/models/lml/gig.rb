module Lml
  class Gig < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[
        category
        checked
        created_at
        date
        name
        series
        source
        status
        updated_at
        venue_id
        tags
      ]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[venue]
    end

    def self.ransackable_scopes(_auth_object = nil)
      %w[
        tags_in
        visible
      ]
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
    belongs_to :upload, optional: true
    has_many :sets, dependent: :delete_all
    has_many :prices, dependent: :delete_all

    scope :eager, -> { order(:date, :start_offset).includes(sets: :act).includes(:venue).includes(:prices) }
    scope :visible, -> { where(hidden: [nil, false]).where.not(status: "draft") }
    # scope :tags_in, ->(*tags) { where("tags ?| array[:matches]", matches:tags) }

    def label
      "#{name} (#{date})"
    end

    def venue_label
      venue&.label
    end

    def tags
      result = []
      result << "series:#{series}" if series
      result << "category:#{category}" if category
      (information_tags || []).each { |tag| result << "information:#{tag}" }
      (genre_tags || []).each { |tag| result << "genre:#{tag}" }
      result
    end

    def genre_tag_list
      (genre_tags || []).join(", ")
    end

    def genre_tag_list=(value)
      self.genre_tags = value.split(",").map(&:strip)
    end

    def information_tag_list
      (information_tags || []).join(", ")
    end

    def information_tag_list=(value)
      self.information_tags = value.split(",").map(&:strip)
    end

    def set_list
      sets.map do |set|
        "#{set.act.name}|#{set.start_offset_time}|#{set.duration}"
      end.join("\n")
    end

    def set_list=(value)
      sets.delete_all
      value.split("\n") do |line|
        act_name, start_offset_time, duration, stage = line.split("|").map(&:strip)
        next if act_name.blank?

        act = Lml::Act.where("lower(name) = ?", act_name.downcase).first
        act ||= Lml::Act.create(name: act_name)
        Lml::Set.create(
          gig: self,
          act: act,
          start_offset_time: start_offset_time,
          duration: duration,
          stage: stage,
        )
      end
    end

    def price_list
      prices.map do |price|
        "#{price.amount}|#{price.description}"
      end.join("\n")
    end

    def price_list=(value)
      prices.delete_all
      value.split("\n") do |line|
        amount, description = line.split("|").map(&:strip)
        next if amount.blank?

        Lml::Price.create(
          gig: self,
          amount: amount,
          description: description,
        )
      end
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
      return unless date && start_offset && venue&.time_zone

      date.in_time_zone(venue.time_zone) + (start_offset / 1_440.0).days
    end
  end
end
