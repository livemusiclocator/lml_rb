# frozen_string_literal: true

module Lml
  class Act < ApplicationRecord
    include Lml::Searchable

    SEARCH_COLUMNS = %w[name country].freeze

    scope :search, ->(query) { search_terms(query, SEARCH_COLUMNS).order(:name) }

    has_many :act_managers, class_name: "Lml::ActManager", foreign_key: :act_id, dependent: :destroy
    has_many :managers, through: :act_managers, source: :user

    def self.ransackable_attributes(_auth_object = nil)
      %w[name country location]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    def self.find_or_create_act_from_line!(line)
      name, location, country = extract_name_location_country(line)
      act = Lml::Act.where("lower(name) = ?", name.downcase).first
      if act
        act.update!(location: location, country: country)
        act
      else
        Lml::Act.create!(name: name, location: location, country: country)
      end
    end

    def self.extract_name_location_country(line)
      match = /(.*) \((.*)\)/.match(line)
      return line unless match

      name = match[1].strip
      location = match[2].strip
      match = %r{(.*)/(.*)}.match(location)

      return [name, location, "Australia"] unless match

      [name, match[1], match[2]]
    end

    def linktree=(value)
      super(value.split("/").last)
    end

    def linktree_url
      "https://linktr.ee/#{linktree}" if linktree.present?
    end

    def bandcamp=(value)
      super(value.sub("https://", "").split(".").first)
    end

    def bandcamp_url
      "https://#{bandcamp}.bandcamp.com" if bandcamp.present?
    end

    def instagram=(value)
      super(value.split("/").last)
    end

    def instagram_url
      "https://www.instagram.com/#{instagram}" if instagram.present?
    end

    def facebook=(value)
      super(value.split("/").last)
    end

    def facebook_url
      "https://www.facebook.com/#{facebook}" if facebook.present?
    end

    def musicbrainz=(value)
      super(value.split("/").last)
    end

    def musicbrainz_url
      "https://musicbrainz.org/artist/#{musicbrainz}" if musicbrainz.present?
    end

    def rym=(value)
      super(value.split("/").last)
    end

    def rym_url
      "https://rateyourmusic.com/artist/#{rym}" if rym.present?
    end

    def spotify=(value)
      super(value.split("/").last)
    end

    def spotify_url
      "https://open.spotify.com/artist/#{spotify}" if spotify.present?
    end

    def wikipedia=(value)
      super(value.split("/").last)
    end

    def wikipedia_url
      "https://en.wikipedia.org/wiki/#{wikipedia}" if wikipedia.present?
    end

    def youtube=(value)
      super(value.split("/").last)
    end

    def youtube_url
      "https://youtube.com/#{youtube}" if youtube.present?
    end

    def genre_list
      (genres || []).join(", ")
    end

    def genre_list=(value)
      self.genres = value.split(",").map(&:strip)
    end

    def label
      country.present? ? "#{name} (#{country})" : name
    end

    def search_label
      label
    end
  end
end
