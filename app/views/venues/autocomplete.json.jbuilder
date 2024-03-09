# frozen_string_literal: true

json.array! @venues do |venue|
  json.id venue.id
  json.label venue.label
end
