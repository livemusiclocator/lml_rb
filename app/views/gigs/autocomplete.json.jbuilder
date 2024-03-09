# frozen_string_literal: true

json.array! @gigs do |gig|
  json.id gig.id
  json.label gig.label
end
