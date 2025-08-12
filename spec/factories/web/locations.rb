# frozen_string_literal: true

FactoryBot.define do
  factory :lml_location, class: "Web::Location" do
    sequence(:internal_identifier) { |n| "LOC#{n.to_s.rjust(3, "0")}" }
    name { Faker::Address.city }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    map_zoom_level { 15 }
    seo_title_format_string { "Visit #{name} - Great Location" }
    visible_in_editions { ["all"] }
  end
end
