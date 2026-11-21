FactoryBot.define do
  factory :track do
    title { Faker::Music::RockBand.song }
    pos { rand(1..20) }
    duration { rand(1..10_000) }
    association :release
  end
end
