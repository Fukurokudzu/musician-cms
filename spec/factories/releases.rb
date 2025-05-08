FactoryBot.define do
  factory :release do
    association :artist
    title { Faker::Music::RockBand.name }
    artist_id { artist }
  end
end
