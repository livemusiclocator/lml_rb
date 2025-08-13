FactoryBot.define do
  factory :lml_venue, class: 'Lml::Venue' do
    time_zone { "Australia/Melbourne" }
    name { "Wonder Palace" }
    address { "48 Fancy Street, Awesomeville" }
  end
end
