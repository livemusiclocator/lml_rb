Date::DATE_FORMATS[:default] = "%a, %d %b %Y"

Date::DATE_FORMATS[:gig_date] = ->(date) {
  "on #{date.strftime('%A %-d%{suffix} %B %Y')}" % { suffix: date.day.ordinalize.last(2) }
}
