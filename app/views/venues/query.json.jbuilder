# frozen_string_literal: true

json.array! @venues do |venue|
  json.id venue.id
  json.name venue.name
end
