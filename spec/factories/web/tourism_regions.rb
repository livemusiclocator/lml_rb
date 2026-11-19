# frozen_string_literal: true

FactoryBot.define do
  factory :web_tourism_region, class: "Web::TourismRegion" do
    internal_identifier { "melbourne" }
    name { "Melbourne" }
  end
end
