FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { "user_#{Faker::Number.number(digits: 5)}" }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    confirmed_at { Time.current }
  end
end
