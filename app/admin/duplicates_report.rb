# frozen_string_literal: true

ActiveAdmin.register_page "Duplicates Report" do
  menu false

  content title: "Potential Duplicate Gigs" do
    start_of_week = Date.today.beginning_of_week
    end_of_week = start_of_week + 6
    @gigs = Lml::Gig.potential_duplicated_gigs(start_of_week..end_of_week)

    gigs_by_venue = @gigs.group_by(&:venue)

    div class: "duplicate-gig-report" do
      if @gigs.empty?
        para "No potential duplicate gigs found for this week. That's good!"
      else

        gigs_by_venue.each do |venue, venue_gigs|
          panel "#{venue&.name} (#{venue_gigs.count} gigs)" do
            # show a table per date for the venue
            gigs_by_date = venue_gigs.group_by(&:date).sort_by { |date, _| date }
            gigs_by_date.each do |date, gigs_for_date|
              div class: "date_section" do
                h4 do
                  span date.to_fs(:default)
                end

                table_for gigs_for_date, class: "index_table" do
                  column "Time" do |gig|
                    gig.start_time || span("(blank)", class: "no-time")
                  end

                  column "Name" do |gig|
                    link_to gig.name, admin_gig_path(gig)
                  end

                  column "Actions" do |gig|
                    links = []
                    links << link_to("Edit", edit_admin_gig_path(gig), class: "member_link")
                    links.join(" ").html_safe
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
