#!/usr/bin/env ruby
# frozen_string_literal: true

class GigSchedulePresenter
  class DaySchedulePresenter
    def initialize(date, gigs, show_duplicates)
      @date = date
      @gigs = gigs.sort_by { |g| g.start_offset || 0 }
      @show_duplicates = show_duplicates
    end

    def day_number
      @date.strftime("%u")
    end

    def header
      @date.strftime("%a %d")
    end

    def duplicates?
      @show_duplicates && time_slots_with_duplicates.any?
    end

    def duplicate_count
      return 0 unless @show_duplicates

      @time_slots_with_duplicates.sum { |_time, gigs| gigs.size }
    end

    def duplicates_header
      "#{duplicate_count} #{"overlapping gig".pluralize(duplicate_count)}" if duplicates?
    end

    def duplicate_slot?(time_slot)
      @show_duplicates && (time_slots_with_duplicates.include? time_slot)
    end

    def time_slots
      @time_slots ||= grouped_gigs.sort_by { |time, _| time || Time.new(0) }
    end

    def grouped_gigs
      @grouped_gigs ||= @gigs.group_by(&:start_time)
    end

    private

    def time_slots_with_duplicates
      return [] unless @show_duplicates

      @time_slots_with_duplicates ||= grouped_gigs.select { |_time, gigs| gigs.size > 1 }
    end
  end

  class WeekSchedulePresenter
    def initialize(week_start, gigs, show_duplicates)
      @gigs = gigs
      @week_start = week_start
      @week_end = week_start + 6.days
      @show_duplicates = show_duplicates
    end

    def header_text
      "Week of #{@week_start.strftime("%d %b %Y")}"
    end

    def visible_days?
      visible_days.present?
    end

    def day_headers
      visible_days.map { |date| date.strftime("%a %d") }
    end

    def visible_days
      @visible_days ||= if @week_start > @week_end
                          []
                        else
                          (0..6).map { |offset| @week_start + offset.days }.select do |date|
                            date.between?(@week_start, @week_end)
                          end

                        end
    end

    def day_schedules
      visible_days.map do |date|
        DaySchedulePresenter.new(date, @gigs.select { |g| g.date == date }, @show_duplicates)
      end
    end
  end

  def initialize(all_gigs, params)
    @all_gigs = all_gigs
    @params = params
    @show_duplicates = params[:scope] == "potential_duplicates"
  end

  def gig_count_text
    "#{@all_gigs.size} #{"gig".pluralize(@all_gigs.size)}"
  end

  def venue_schedules
    @all_gigs
      .sort_by { |venue, _| venue.name }
      .group_by(&:venue)
      .transform_values { |gigs| GigSchedulePresenter.new(gigs, @params) }
  end

  def week_schedules
    gigs_by_week_start = @all_gigs.group_by do |g|
      g.date&.beginning_of_week(:monday)
    end
    gigs_by_week_start.map do |week_start, gigs|
      WeekSchedulePresenter.new(week_start, gigs,
                                @show_duplicates,)
    end
  end
end
