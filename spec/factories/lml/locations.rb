FactoryBot.define do
  factory :lml_location, class: "Lml::Location" do
    sequence(:internal_identifier) { |n| "LOC#{n.to_s.rjust(3, "0")}" }
    name { Faker::Address.city }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end
end
