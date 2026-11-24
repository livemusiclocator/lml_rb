# frozen_string_literal: true

FactoryBot.define do
  factory :web_tourism_region, class: "Web::TourismRegion" do
    sequence(:internal_identifier) { |n| "region_#{n}" }
    sequence(:name) { |n| "Region #{n}" }
  end
end
