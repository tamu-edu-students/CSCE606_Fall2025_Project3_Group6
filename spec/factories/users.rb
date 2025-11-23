FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { Faker::Internet.unique.user_name.gsub(/[^a-zA-Z0-9_]/, '_') }
    password { "Password123" }
    password_confirmation { "Password123" }
    confirmed_at { Time.current }
  end
end
