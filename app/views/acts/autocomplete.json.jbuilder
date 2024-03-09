# frozen_string_literal: true

json.array! @acts do |act|
  json.id act.id
  json.name act.name
end
