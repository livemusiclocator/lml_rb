# frozen_string_literal: true

module Web
  class GigSearch
    include ActiveModel::Model
    include ActiveModel::Attributes

    GENRES = <<~GENRES_CSV
      Americana, Rock, Pop, Hip-Hop, R&B, Soul, Jazz, Classical, Electronic, Country, Metal, Folk, Blues, Reggae,
      Latin, World, Gospel, Dance, Punk, Alternative, Experimental, Indie, Ambient, Hardcore, Industrial,
      Garage, Trance, House, Techno, Drum and Bass, Dubstep, Funk, Chill, Disco, Opera, Swing, Acoustic,
      New Wave, DJ, Covers, Tribute
    GENRES_CSV
             .split(/,\s*/).freeze
    DATE_RANGES = %w[today tomorrow thisWeek nextWeek customDate].freeze

    # Configuration for display formatting
    CONFIG = {
      date_ranges: {
        "today" => "today",
        "tomorrow" => "tomorrow",
        "weekend" => "this weekend",
        "thisWeek" => "this week",
        "nextWeek" => "next week",
      },
      fallback_title: "Live Music Listings",
      multiple_genres_text: "Live Music (multiple genres)",
      default_music_text: "Live Music",
    }.freeze

    attribute :location, :string
    attribute :date_range, :string, default: "thisWeek"
    attribute :genre, array: true, default: []
    attribute :venue_ids, array: true, default: []
    attribute :custom_date

    def initialize(params, explorer_config)
      super(params)

      @explorer_config = explorer_config
    end

    # TODO : Maybe move out all the title gen stuff ?
    def title
      genre_text = format_genre_text
      location_text = format_location
      date_text = format_date

      [genre_text, location_text, date_text].compact.join(" ").strip
    end

    private

    def extract_valid_genres
      return [] if genre.blank?

      valid_genres = genre.filter_map do |genre_name|
        GENRES.find { |valid_genre| valid_genre.downcase == genre_name.downcase }
      end
      valid_genres.uniq(&:downcase).sort_by(&:downcase)
    end

    def format_genre_text
      valid_genres = extract_valid_genres

      return CONFIG[:default_music_text] unless valid_genres.present?

      return CONFIG[:multiple_genres_text] unless valid_genres.size <= 3

      "#{valid_genres.to_sentence(last_word_connector: " and ")} gigs"
    end

    def format_location
      if location
        location_config = @explorer_config.locations.find do |location_config|
          location_config.internal_identifier == location.downcase
        end
      end

      location_config ||= @explorer_config.default_location_object
      location_config&.in_location_text
    end

    def format_date
      return format_custom_date if date_range == "customDate"
      return CONFIG[:date_ranges][date_range] if CONFIG[:date_ranges][date_range]

      ""
    end

    def format_custom_date
      return "" unless custom_date.present?

      begin
        Date.parse(custom_date).to_fs(:gig_date)
      rescue Date::Error
        ""
      end
    end
  end
end
