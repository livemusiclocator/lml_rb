class Web::GigsController < ApplicationController
  layout 'web/layouts/application'

  def index
    # Main gigs list with Explorer layout
    @gigs = stub_gigs_data
    render layout: 'web/layouts/explorer'
  end

  def alt
    # Alternative gigs list view (without Explorer layout)
    @gigs = stub_gigs_data
    render :index
  end

  def show
    # Single gig details
    @gig = stub_gig_data(params[:id])
    render layout: 'web/layouts/explorer'
  end

  def about
    # About page
  end

  def events
    # Events page
  end

  private

  def stub_gigs_data
    # TODO: Replace with actual gig data from useGigList hook
    [
      {
        id: 1,
        name: 'Jazz Night at The Corner',
        venue_name: 'The Corner Hotel',
        address: '57 Swan St, Richmond VIC 3121',
        start_time: 2.days.from_now,
        end_time: 2.days.from_now + 3.hours,
        genres: ['Jazz', 'Blues'],
        ticket_url: 'https://example.com/tickets/1'
      },
      {
        id: 2,
        name: 'Electronic Music Festival',
        venue_name: 'Forum Melbourne',
        address: '154 Flinders St, Melbourne VIC 3000',
        start_time: 1.week.from_now,
        end_time: 1.week.from_now + 4.hours,
        genres: ['Electronic', 'Techno'],
        ticket_url: 'https://example.com/tickets/2'
      }
    ]
  end

  def stub_gig_data(id)
    # TODO: Replace with actual gig data from useGig hook
    {
      id: id.to_i,
      name: 'Jazz Night at The Corner',
      #description: 'An amazing evening of jazz music featuring local and international artists.',
      venue: {
        name: 'The Corner Hotel',
        address: '57 Swan St, Richmond VIC 3121'
      },
      start_time: 2.days.from_now,
      end_time: 2.days.from_now + 3.hours,
      genres: ['Jazz', 'Blues'],
      sets: [
        { artist: 'The Jazz Quartet', start_time: '8:00 PM', duration: '1 hour' },
        { artist: 'Blues Brothers Tribute', start_time: '9:30 PM', duration: '1.5 hours' }
      ],
      prices: [
        { amount: 25, description: 'General Admission' },
        { amount: 45, description: 'VIP Package' }
      ],
      ticket_url: 'https://example.com/tickets/1',
      hero_image: nil,
      info_tags: ['18+', 'Licensed Venue', 'Food Available'],
      series: nil
    }
  end
end
