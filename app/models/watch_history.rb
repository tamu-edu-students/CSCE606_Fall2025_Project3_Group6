class WatchHistory < ApplicationRecord
  belongs_to :user
  has_many :watch_logs, dependent: :destroy

  validates :user_id, presence: true, uniqueness: true
end
