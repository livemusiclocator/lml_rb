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
    enum :ticket_status, { selling_fast: "selling_fast", sold_out: "sold_out" }, prefix: true

    belongs_to :venue, optional: true
    belongs_to :upload, optional: true
    has_many :sets, dependent: :delete_all
    has_many :prices, dependent: :delete_all

    scope :eager, -> { order(:date, :start_offset).includes(sets: :act).includes(:venue).includes(:prices) }
    scope :visible, -> { where(hidden: [nil, false]).where.not(status: "draft") }

    def suggest_tags!
      return if internal_description.blank?

      update!(proposed_genre_tags: Lml::StochasticParrot.new.gist(internal_description))
    end

    def label
      "#{name} (#{date})"
    end

    def venue_label
      venue&.label
    end

    def tags
      result = []
      (information_tags || []).each { |tag| result << "information:#{tag}" }
      genres = genre_tags || []
      genres = proposed_genre_tags || [] if genres.empty?
      genres.each { |tag| result << "genre:#{tag}" }
      result
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
