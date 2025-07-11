class Web::GigSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  LOCATIONS = %w[anywhere melbourne stkilda goldfields].freeze
  GENRES = <<~EOS
    Americana, Rock, Pop, Hip-Hop, R&B, Soul, Jazz, Classical, Electronic, Country, Metal, Folk, Blues, Reggae,
    Latin, World, Gospel, Dance, Punk, Alternative, Experimental, Indie, Ambient, Hardcore, Industrial,
    Garage, Trance, House, Techno, Drum and Bass, Dubstep, Funk, Chill, Disco, Opera, Swing, Acoustic,
    New Wave, DJ, Covers, Tribute
  EOS
           .split(/,\s*/).freeze
  DATE_RANGES = %w[today tomorrow thisWeek nextWeek customDate].freeze

  # Configuration for display formatting
  CONFIG = {
    locations: {
      'anywhere' => 'anywhere',
      'melbourne' => 'in Melbourne',
      'stkilda' => 'in St Kilda',
      'goldfields' => 'in Goldfields'
    },
    date_ranges: {
      'today' => 'today',
      'tomorrow' => 'tomorrow',
      'thisWeek' => 'this week',
      'nextWeek' => 'next week'
    },
    fallback_title: 'Live Music Listings',
    multiple_genres_text: 'Live Music (multiple genres)',
    default_music_text: 'Live Music'
  }.freeze

  attribute :location, :string
  attribute :date_range, :string
  attribute :genre, array: true, default: []
  attribute :venue_ids, array: true, default: []
  attribute :custom_date

  validates :location, inclusion: { in: LOCATIONS }
  validates :date_range, inclusion: { in: DATE_RANGES }
  validates :custom_date, presence: true, if: -> { date_range == 'customDate' }
  validate :custom_date_format, if: -> { date_range == 'customDate' && custom_date.present? }

  def initialize(params = {})
    super(params)
  end

  def title
    return CONFIG[:fallback_title] unless valid?

    genre_text = build_genre_text(valid_genres)
    location_text = format_location
    date_text = format_date

    [genre_text, location_text, date_text].join(' ')
  end

  def to_meta_tags
    {
      title: title,
      keywords: build_keywords,
    }
  end

  private

  def extract_valid_genres
    return [] if genre.blank?

    # Extract and validate genres
    genre_names = genre.map { |g| extract_genre_name(g) }
    valid_genres = find_valid_genres(genre_names)

    # Remove duplicates and sort
    valid_genres.uniq { |g| g.downcase }.sort_by(&:downcase)
  end

  def extract_genre_name(genre_string)
    # todo: this should not be needed once the query string format has been changed
    genre_string.to_s.gsub(/^genre:/, '')
  end

  def find_valid_genres(genre_names)
    genre_names.filter_map do |genre_name|
      GENRES.find { |valid_genre| valid_genre.downcase == genre_name.downcase }
    end
  end

  def build_genre_text(valid_genres)
    if valid_genres.present? && valid_genres.size <= 3
      "#{valid_genres.to_sentence(last_word_connector: ' and ')} gigs"
    else
      valid_genres.size > 3 ? CONFIG[:multiple_genres_text] : CONFIG[:default_music_text]
    end
  end

  def format_location
    CONFIG[:locations][location]
  end

  def format_date
    date_range == 'customDate' ? format_custom_date : CONFIG[:date_ranges][date_range]
  end

  def custom_date_format
    return unless custom_date.present?

    begin
      Date.parse(custom_date)
    rescue Date::Error
      errors.add(:custom_date, 'must be a valid date in yyyy-mm-dd format')
    end
  end

  def format_custom_date
    return custom_date unless custom_date.present?

    begin
      Date.parse(custom_date).to_fs(:gig_date)
    rescue Date::Error
      custom_date # fallback to original if parsing fails
    end
  end

  def build_keywords
    keywords = ['live music', 'gigs', 'concerts', 'Melbourne', 'venues', 'events']

    # Add location-specific keywords
    case location
    when 'stkilda'
      keywords += ['St Kilda', 'St Kilda music']
    when 'goldfields'
      keywords += ['Goldfields', 'regional music']
    when 'melbourne'
      keywords += ['Melbourne CBD', 'inner city']
    end

    # Add genre keywords
    keywords += valid_genres.map(&:downcase) if valid_genres.present?

    keywords.uniq.join(', ')
  end

  def valid_genres
    @valid_genres ||= extract_valid_genres
  end
end
