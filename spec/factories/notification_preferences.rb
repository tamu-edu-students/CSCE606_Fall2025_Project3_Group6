FactoryBot.define do
  factory :notification_preference do
    user { nil }
    review_created { false }
    review_voted { false }
    user_followed { false }
  end
end
