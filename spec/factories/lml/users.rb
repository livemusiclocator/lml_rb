# frozen_string_literal: true

FactoryBot.define do
  factory :lml_user, class: "Lml::User" do
    sequence(:email) { |n| "user#{n}@example.com" }
    display_name { "Backstage Betty" }
    password { "supersecret123" }
    password_confirmation { "supersecret123" }
    confirmed_at { Time.current }

    trait :admin do
      admin { true }
    end
  end
end
