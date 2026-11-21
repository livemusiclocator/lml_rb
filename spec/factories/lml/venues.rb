# frozen_string_literal: true

FactoryBot.define do
  factory :lml_venue, class: "Lml::Venue" do
    time_zone { "Australia/Melbourne" }
    name { "Wonder Palace" }
    address { "48 Fancy Street, Awesomeville" }
    tourism_region factory: :web_tourism_region
  end
end
