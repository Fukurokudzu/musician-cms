FactoryBot.define do
  factory :release do
    association :artist
    title { 'LLN 1348' }
    artist_id { artist }
  end
end
