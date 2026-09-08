# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: "Live Music Locator Admin" do
    coverage = Lml::CoverageStats.new

    panel "Coverage" do
      para do
        text_node "Across Victoria we hold "
        strong number_with_delimiter(coverage.venues)
        text_node " venues in the regions the gig guide serves, are currently profiling gigs at "
        strong number_with_delimiter(coverage.active_venues)
        text_node " of them, and publish "
        strong coverage.gigs_per_week.to_s
        text_node " gigs a week averaged over the year to #{coverage.period.last.to_fs(:long)}."
      end

      table do
        thead do
          tr do
            th "Region"
            th "Venues"
            th "Profiling (12 months)"
            th "Profiling (90 days)"
            th "Gigs a week"
          end
        end
        tbody do
          coverage.regions.each do |region|
            tr do
              td do
                text_node region.name
                span(" (outside Victoria)", class: "empty") unless region.victorian?
              end
              td number_with_delimiter(region.venues)
              td number_with_delimiter(region.active)
              td number_with_delimiter(region.recently_active)
              td region.gigs_per_week.to_s
            end
          end
          tr do
            td(b { "Victoria" })
            td(b { number_with_delimiter(coverage.venues) })
            td(b { number_with_delimiter(coverage.active_venues) })
            td(b { number_with_delimiter(coverage.recently_active_venues) })
            td(b { coverage.gigs_per_week.to_s })
          end
        end
      end
    end

    if coverage.unserved_locations.any?
      panel "Venues no live region serves" do
        para class: "empty" do
          "#{number_with_delimiter(coverage.unserved_venues)} venues sit in a location that is not " \
            "publicly selectable, so the gig guide never shows them. Some are interstate; a location " \
            "spelled differently to its region - \"St Kilda\" rather than \"stkilda\" - is a venue we " \
            "have lost track of."
        end
        table do
          thead do
            tr do
              th "Location"
              th "Venues"
            end
          end
          tbody do
            coverage.listed_unserved_locations.each do |location, count|
              tr do
                td { link_to location, admin_venues_path(q: { location_i_cont: location }) }
                td count.to_s
              end
            end
            if coverage.unlisted_unserved_locations.positive?
              tr do
                td(class: "empty") { "and #{coverage.unlisted_unserved_locations} more locations" }
                td ""
              end
            end
          end
        end
      end
    end

    start_of_week = Date.today.beginning_of_week
    start_of_last_week = start_of_week - 7
    end_of_week = start_of_week + 6

    venue_gigs = Lml::Gig.where(date: (start_of_week..end_of_week)).group(:date, :venue_id).count

    panel "Potential duplicates" do
      table do
        thead do
          tr do
            td("Date")
            td("Time")
            td("Venue")
            td("Gig")
            td("")
          end
        end
        tbody do
          gigs = []

          venue_gigs.each do |value|
            key, count = *value
            date, venue_id = *key
            next unless count > 1

            gigs += Lml::Gig.where(date: date, venue_id: venue_id)
          end

          gigs.each do |gig|
            tr do
              td(gig.date)
              td(gig.start_time)
              venue_name = gig.venue ? gig.venue.name : "(no venue)"
              td(venue_name)
              td(gig.name)
              td { link_to "Edit", admin_gig_path(gig) }
            end
          end
        end
      end
    end

    this_week_total = 0
    gigs = Lml::Gig.where(date: (start_of_week..end_of_week)).group(:date).count

    panel "This week's gigs" do
      table do
        tbody do
          (start_of_week..end_of_week).each do |date| # 7 days
            count = gigs[date] || 0
            this_week_total += count
            tr do
              td { link_to admin_date(date), admin_gigs_path(q: { date_gteq: date, date_lteq: date }) }
              td count
            end
          end
          tr do
            td(b { "Total" })
            td(b { this_week_total })
          end
        end
      end
    end

    gigs = Lml::Gig.where(date: (start_of_last_week...start_of_week)).group(:date).count

    last_week_total = 0
    panel "Last week's gigs" do
      table do
        tbody do
          (start_of_last_week...start_of_week).each do |date| # 7 days
            count = gigs[date] || 0
            last_week_total += count
            tr do
              td { link_to admin_date(date), admin_gigs_path(q: { date_gteq: date, date_lteq: date }) }
              td count
            end
          end
          tr do
            td(b { "Total" })
            td(b { last_week_total })
          end
        end
      end
    end
  end
end
