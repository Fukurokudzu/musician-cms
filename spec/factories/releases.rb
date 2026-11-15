FactoryBot.define do
  factory :release do
    association :artist
    sequence(:title) { |n| "#{Faker::Music::RockBand.name} #{n}" }
    status { :draft }

    trait :published do
      status { :published }
    end
  end
end
