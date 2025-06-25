module Web::ApplicationHelper
  def nav_item_classes(is_active)
    base_styles = "py-4 px-2 text-gray-200"
    if is_active
      "#{base_styles} font-semibold"
    else
      "#{base_styles} font-normal transition duration-200 hover:text-gray-300"
    end
  end

  # Route helpers for navigation
  def web_root_path
    "/web"
  end

  def web_about_path
    "/web/about"
  end

  def web_events_path
    "/web/events"
  end

  def web_gig_path(gig)
    "/web/gigs/#{gig[:id]}"
  end

  # Theme helpers (stubbed)
  def theme_brandmark
    # TODO: Replace with actual theme logic from getTheme() function
    'lml-brandmark.svg'
  end

  def theme_title
    # TODO: Replace with actual theme logic from getTheme() function
    'Live Music Locator'
  end

  # Gig data helpers (moved from previous implementation)
  def gig_filter_options
    # TODO: Replace with actual filter options logic from useGigFilterOptions hook
    {
      date_ranges: {
        today: { id: 'today', caption: 'Today', selected: false, ui: 'button' },
        tomorrow: { id: 'tomorrow', caption: 'Tomorrow', selected: false, ui: 'button' },
        this_week: { id: 'this_week', caption: 'This Week', selected: false, ui: 'button' },
        next_week: { id: 'next_week', caption: 'Next Week', selected: false, ui: 'button' },
        this_month: { id: 'this_month', caption: 'This Month', selected: false, ui: 'button' },
        custom_date: { id: 'customDate', caption: 'Custom Date', selected: false, ui: 'datetime' }
      },
      tag_categories: [
        {
          id: 'genres',
          caption: 'Genres',
          values: [
            { id: 'rock', value: 'Rock', selected: false, count: 15 },
            { id: 'jazz', value: 'Jazz', selected: false, count: 8 },
            { id: 'electronic', value: 'Electronic', selected: false, count: 12 }
          ]
        }
      ],
      all_venues: [
        { id: 'venue1', name: 'The Corner Hotel', selected: false, count: 5 },
        { id: 'venue2', name: 'Forum Melbourne', selected: false, count: 3 }
      ],
      custom_date: params[:customDate]
    }
  end

  def active_gig_filter_options
    # TODO: Replace with actual active filter logic from useActiveGigFilterOptions hook
    active_filters = []
    
    # Check for active date range filters
    if params[:dateRange].present?
      date_range = gig_filter_options[:date_ranges][params[:dateRange].to_sym]
      if date_range
        active_filters << {
          id: "dateRange_#{params[:dateRange]}",
          caption: date_range[:caption],
          count: nil
        }
      end
    end
    
    # Check for active tag filters
    if params[:tags].present?
      Array(params[:tags]).each do |tag_id|
        gig_filter_options[:tag_categories].each do |category|
          tag = category[:values].find { |v| v[:id] == tag_id }
          if tag
            active_filters << {
              id: "tag_#{tag_id}",
              caption: tag[:value],
              count: tag[:count]
            }
          end
        end
      end
    end
    
    # Check for active venue filters
    if params[:venues].present?
      Array(params[:venues]).each do |venue_id|
        venue = gig_filter_options[:all_venues].find { |v| v[:id] == venue_id }
        if venue
          active_filters << {
            id: "venue_#{venue_id}",
            caption: venue[:name],
            count: venue[:count]
          }
        end
      end
    end
    
    active_filters
  end

  def show_festival_logo?(gig)
    # TODO: Replace with actual logic for determining if festival logos should be shown
    gig[:series]&.present? && (gig[:series].include?('LBMF') || gig[:series].include?('St Kilda Festival'))
  end

  def format_gig_time(time)
    # TODO: Replace DateTimeDisplay component functionality
    return 'TBD' unless time
    time.strftime("%l:%M %p").strip
  end

  def format_gig_date(time)
    # TODO: Replace DateTimeDisplay component functionality  
    return 'TBD' unless time
    time.strftime("%a, %b %d")
  end

  # About page data (moved from About.jsx)
  def team_members
    # TODO: Move this to a YAML file or database
    [
      { name: 'Alex Johnson', role: 'Lead Developer' },
      { name: 'Sarah Mitchell', role: 'Content Manager' },
      { name: 'Mike Chen', role: 'Data Analyst' },
      { name: 'Emma Thompson', role: 'Community Coordinator' },
      { name: 'James Wilson', role: 'Venue Relations' },
      { name: 'Lisa Rodriguez', role: 'Marketing Specialist' },
      { name: 'Tom Anderson', role: 'Quality Assurance' },
      { name: 'Rachel Green', role: 'Social Media Manager' },
      { name: 'David Kim', role: 'Backend Developer' },
      { name: 'Sophie Turner', role: 'Event Coordinator' },
      { name: 'Mark Davis', role: 'Partnership Manager' },
      { name: 'Nina Patel', role: 'User Experience Designer' },
      { name: 'Chris Brown', role: 'Mobile App Developer' },
      { name: 'Amanda White', role: 'Database Administrator' },
      { name: 'Ryan Moore', role: 'Music Curator' },
      { name: 'Kelly Liu', role: 'Operations Manager' },
      { name: 'Jordan Taylor', role: 'Frontend Developer' },
      { name: 'Megan Clark', role: 'Customer Support' },
      { name: 'Andrew Lee', role: 'Technical Writer' },
      { name: 'Olivia Martin', role: 'Event Photographer' },
      { name: 'Brandon Hall', role: 'Sound Engineer' },
      { name: 'Grace Wong', role: 'Graphic Designer' },
      { name: 'Tyler Scott', role: 'Music Journalist' },
      { name: 'Hannah Adams', role: 'Festival Coordinator' },
      { name: 'Nathan Phillips', role: 'Audio Technician' },
      { name: 'Victoria Chang', role: 'Public Relations' },
      { name: 'Ethan Roberts', role: 'Video Producer' },
      { name: 'Chloe Murphy', role: 'Volunteer Coordinator' },
      { name: 'Isaac Foster', role: 'Research Analyst' },
      { name: 'Zoe Cooper', role: 'Community Outreach' }
    ]
  end

  def key_members
    # TODO: Move this to a YAML file or database
    [
      { name: 'Jennifer Walsh', role: 'Executive Director & Founder' },
      { name: 'Michael O\'Brien', role: 'Technical Director' },
      { name: 'Sarah Johnson', role: 'Operations Director' }
    ]
  end
end