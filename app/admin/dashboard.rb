# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: "Live Music Locator Admin" do
    start_of_week = Date.today.beginning_of_week
    start_of_last_week = start_of_week - 7
    end_of_week = start_of_week + 6

    venue_gigs = Lml::Gig.where(date: (start_of_week..end_of_week)).group(:date, :venue_id).count

    panel "Potential duplicates" do
      table do
        thead do
          tr do
            td("Date")
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
              venue_name =  if gig.venue then gig.venue.name else "(no venue)" end
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
