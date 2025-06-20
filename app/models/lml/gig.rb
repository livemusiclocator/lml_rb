module Lml
  class Gig < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[
        category
        checked
        created_at
        date
        hidden
        name
        series
        source
        status
        updated_at
        upload_id
        venue_id
      ]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[venue]
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
    enum :ticket_status, { selling_fast: "selling_fast", sold_out: "sold_out" }, prefix: true

    belongs_to :venue, optional: true
    belongs_to :upload, optional: true

    has_many :sets, dependent: :delete_all
    has_many :prices, dependent: :delete_all

    scope :eager, -> { order(:date, :start_offset).includes(sets: :act).includes(:venue).includes(:prices) }
    scope :visible, -> { where(hidden: [nil, false]).where.not(status: "draft") }

    def suggest_tags!(force: false)
      return if internal_description.blank?
      return if !force && (proposed_genre_tags || []).present?

      update!(proposed_genre_tags: Lml::StochasticParrot.new.gist(internal_description))
    end

    def label
      "#{name} (#{date})"
    end

    def venue_label
      venue&.label
    end

    def proposed_genre_tag_list
      (proposed_genre_tags || []).join("\n")
    end

    def genre_tag_list
      (genre_tags || []).join("\n")
    end

    def genre_tag_list=(value)
      self.genre_tags = value.split("\n").map(&:strip)
    end

    def information_tag_list
      (information_tags || []).join("\n")
    end

    def information_tag_list=(value)
      self.information_tags = value.split("\n").map(&:strip)
    end

    def set_list
      sets.map(&:line).join("\n")
    end

    def set_list=(value)
      sets.delete_all
      value.split("\n") { |line| Lml::Set.create_for_gig_from_line!(self, line) }
    end

    def price_list
      prices.map(&:line).join("\n")
    end

    def price_list=(value)
      prices.delete_all
      value.split("\n") { |line| Lml::Price.create_for_gig_from_line!(self, line) }
    end

    def start_time=(value)
      self.start_offset = nil

      return if value.blank?

      time = Time.parse(value)
      self.start_offset = (time.hour * 60) + time.min
    end

    def start_time
      return nil unless start_offset

      Lml::Formatting.offset_to_time(start_offset)
    end

    def finish_time=(value)
      self.duration = nil

      return if value.blank?
      return unless start_offset

      time = Time.parse(value)
      finish_offset = (time.hour * 60) + time.min
      finish_offset += 24 * 60 if finish_offset < start_offset
      self.duration = finish_offset - start_offset
    end

    def finish_time
      return nil unless start_offset && duration

      finish_offset = start_offset + duration
      finish_offset -= 24 * 60 if finish_offset > 24 * 60
      Lml::Formatting.offset_to_time(finish_offset)
    end

    def start_timestamp
      return unless date && venue&.time_zone && start_offset

      date.in_time_zone(venue.time_zone) + (start_offset / 1_440.0).days
    end

    def finish_timestamp
      return unless date && venue&.time_zone && start_offset && duration

      date.in_time_zone(venue.time_zone) + ((start_offset + duration) / 1_440.0).days
    end

    def lml_url
      "https://lml.live/gigs/#{id}"
    end

    def display_name
      [name, venue_label, date&.to_formatted_s].compact.join(" - ")
    end

    def rss_description
      [name, venue_label, date&.to_formatted_s].compact.join(" - ")
    end
  end
end
