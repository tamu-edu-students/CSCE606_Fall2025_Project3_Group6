FactoryBot.define do
  factory :watch_log do
    association :watch_history
    association :movie
    watched_on { Date.current }
  end
end
