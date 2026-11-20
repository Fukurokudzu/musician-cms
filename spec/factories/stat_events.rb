FactoryBot.define do
  factory :stat_event do
    kind { 'play' }
    association :release
    track { nil }

    trait :play do
      kind { 'play' }
    end

    trait :download do
      kind { 'download' }
    end
  end
end
