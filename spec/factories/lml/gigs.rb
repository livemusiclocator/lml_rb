FactoryBot.define do
  factory :lml_gig, class: 'Lml::Gig' do
    name { "Giggy McGigface" }
    date { "2025-07-11" }
    venue factory: :lml_venue
  end
end
