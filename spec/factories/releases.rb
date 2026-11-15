FactoryBot.define do
  factory :release do
    association :artist
    title { Faker::Music::RockBand.name }
    status { :draft }

    trait :published do
      status { :published }
    end
  end
end
