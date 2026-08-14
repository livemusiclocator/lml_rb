# frozen_string_literal: true

json.array! @acts do |act|
  json.id act.id
  json.label act.label
  json.genres act.genres
end
