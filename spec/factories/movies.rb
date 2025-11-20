FactoryBot.define do
  factory :movie do
    sequence(:tmdb_id) { |n| n }
    title { "MyString" }
    overview { "MyText" }
    poster_path { "MyString" }
    release_date { "2025-11-15" }
    runtime { 1 }
    popularity { 1.5 }
    cached_at { "2025-11-15 04:57:44" }
  end
end
