require 'rails_helper'

RSpec.describe Web::GigSearch, type: :model do
  describe '#title' do
    let(:base_params) { { location: 'melbourne', date_range: 'today' } }

    def build_search(**params)
      described_class.new(base_params.merge(params))
    end

    shared_examples 'shows live music with location and date' do |expected_prefix = 'Live Music'|
      it "shows '#{expected_prefix}' with location and date" do
        expect(subject.title).to eq("#{expected_prefix} in Melbourne today")
      end
    end

    shared_examples 'handles different locations' do |genre_text|
      %w[melbourne stkilda goldfields anywhere].each do |location|
        it "works with #{location} location" do
          search = build_search(genres: genres, location: location)
          location_name = location == 'stkilda' ? 'St Kilda' : location.capitalize
          location_name = location if location == 'anywhere'

          expected = "#{genre_text} #{location == 'anywhere' ? location : "in #{location_name}"} today"
          expect(search.title).to eq(expected)
        end
      end
    end

    shared_examples 'handles different date ranges' do |genre_text|
      {
        'today' => 'today',
        'tomorrow' => 'tomorrow',
        'thisWeek' => 'this week',
        'nextWeek' => 'next week'
      }.each do |date_range, expected_text|
        it "works with #{date_range}" do
          search = build_search(genres: genres, date_range: date_range)
          expect(search.title).to eq("#{genre_text} in Melbourne #{expected_text}")
        end
      end
    end

    context 'with no genres' do
      let(:genres) { [] }
      subject { build_search(genres: genres) }

      include_examples 'shows live music with location and date'
      include_examples 'handles different locations', 'Live Music'
      include_examples 'handles different date ranges', 'Live Music'
    end

    context 'with single genre' do
      let(:genres) { ['Rock'] }
      subject { build_search(genres: genres) }

      include_examples 'shows live music with location and date', 'Rock gigs'
      include_examples 'handles different locations', 'Rock gigs'
      include_examples 'handles different date ranges', 'Rock gigs'
    end

    context 'with multiple genres' do
      context 'with 2 genres' do
        let(:genres) { ['Acoustic', 'Folk'] }
        subject { build_search(genres: genres) }

        include_examples 'shows live music with location and date', 'Acoustic and Folk gigs'
      end

      context 'with 3 genres' do
        let(:genres) { ['Acoustic', 'Folk', 'Americana'] }
        subject { build_search(genres: genres) }

        include_examples 'shows live music with location and date', 'Acoustic, Americana and Folk gigs'
      end

      it 'sorts genres alphabetically' do
        search = build_search(genres: ['Rock', 'Acoustic', 'Folk'])
        expect(search.title).to eq('Acoustic, Folk and Rock gigs in Melbourne today')
      end

      it 'removes duplicate genres (case-insensitive)' do
        search = build_search(genres: ['jazz', 'Jazz', 'Rock'])
        expect(search.title).to eq('Jazz and Rock gigs in Melbourne today')
      end
    end

    context 'with more than 3 genres' do
      let(:genres) { ['Rock', 'Folk', 'Jazz', 'Blues'] }
      subject { build_search(genres: genres) }

      include_examples 'shows live music with location and date', 'Live Music (multiple genres)'
    end

    context 'with custom date' do
      it 'shows custom date when provided' do
        search = build_search(location: "melbourne", date_range: 'customDate', custom_date: '2025-01-15')
        expect(search.title).to eq('Live Music in Melbourne on Wednesday 15th January 2025')
      end
      it 'displays fallback title if the date range is missing' do
        search = build_search(location: "melbourne", date_range: 'customDate')
        expect(search).to_not be_valid
        expect(search.title).to eq('Live Music Listings')
      end
      it 'displays fallback title if the date range is not a valid iso date' do
        search = build_search(location: "melbourne", date_range: 'customDate', custom_date: "This is not a date")
        expect(search).to_not be_valid
        expect(search.title).to eq('Live Music Listings')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_search) { build_search(location: 'invalid') }

      before { allow(invalid_search).to receive(:valid?).and_return(false) }

      it 'returns fallback text when model is invalid' do
        expect(invalid_search.title).to eq('Live Music Listings')
      end
    end

    context 'with invalid genres' do
      it 'filters out invalid genres' do
        search = build_search(genres: ['Rock', 'InvalidGenre'])
        expect(search.title).to eq('Rock gigs in Melbourne today')
      end

      it 'shows "Live Music" when all genres are invalid' do
        search = build_search(genres: ['InvalidGenre1', 'InvalidGenre2'])
        expect(search.title).to eq('Live Music in Melbourne today')
      end
    end
  end
end
