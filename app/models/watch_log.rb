class WatchLog < ApplicationRecord
  belongs_to :watch_history
  belongs_to :movie

  attr_accessor :incoming_rating

  validates :watched_on, presence: true
  validate :watched_on_cannot_be_in_future

  before_validation :assign_user_from_watch_history
  after_create :sync_to_log
  after_destroy :remove_synced_log

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

  # Mirror watch history entries into the legacy logs table so stats
  # can use rating/rewatch fields stored there.
  def sync_to_log
    return unless user_id && movie_id && watched_on

    rating_value = incoming_rating.presence
    # Fallback to latest review rating for this movie/user if none provided
    if rating_value.blank?
      rating_value = Review.where(user_id: user_id, movie_id: movie_id).order(created_at: :desc).limit(1).pick(:rating)
    end
    return unless rating_value

    log = Log.find_or_initialize_by(user_id: user_id, movie_id: movie_id, watched_on: watched_on)
    log.rating = rating_value
    prior_watch = Log.where(user_id: user_id, movie_id: movie_id).where.not(watched_on: watched_on).exists? ||
      watch_history&.watch_logs&.where(movie_id: movie_id).where.not(id: id).exists?
    log.rewatch = prior_watch || log.rewatch || false
    log.save!
  rescue StandardError => e
    Rails.logger.error("WatchLog#sync_to_log error: #{e.message}")
  end

  def remove_synced_log
    return unless user_id && movie_id && watched_on

    log = Log.find_by(user_id: user_id, movie_id: movie_id, watched_on: watched_on)
    log&.destroy
  rescue StandardError => e
    Rails.logger.error("WatchLog#remove_synced_log error: #{e.message}")
  end
end
