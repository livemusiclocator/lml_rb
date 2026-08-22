# frozen_string_literal: true

FactoryBot.define do
  factory :lml_api_token, class: "Lml::ApiToken" do
    user factory: :lml_user
    name { "Import script" }
    token_digest { Lml::ApiToken.digest("lml_admin_#{SecureRandom.hex(8)}") }

    trait :revoked do
      revoked_at { 1.day.ago }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
