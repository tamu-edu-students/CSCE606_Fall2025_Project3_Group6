class WatchLog < ApplicationRecord
  belongs_to :watch_history
  belongs_to :movie

  validates :watched_on, presence: true
  validate :watched_on_cannot_be_in_future

  before_validation :assign_user_from_watch_history

  def watched_on_cannot_be_in_future
    return if watched_on.blank?
    if watched_on > Date.current
      errors.add(:watched_on, "can't be in the future")
    end
  end

  private

  def assign_user_from_watch_history
    if self.user_id.blank? && self.watch_history.present?
      self.user_id = self.watch_history.user_id
    end
  end
end
