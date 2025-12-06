class Review < ApplicationRecord
  belongs_to :user
  belongs_to :movie
  has_many :votes, dependent: :destroy

  after_create :notify_followers

  validates :body, presence: true, length: { minimum: 10 }
  validates :rating, presence: true, inclusion: { in: 1..10 }
  validates :user_id, uniqueness: { scope: :movie_id }

  scope :by_date, -> { order(created_at: :desc) }
  scope :by_score, -> { order(cached_score: :desc) }

  def score
    cached_score || 0
  end

  def update_score!
    update(cached_score: votes.sum(:value))
  end

  private

  # When a user posts a review we notify their followers
  def notify_followers
    return unless user&.followers&.any?

    user.followers.find_each do |follower|
      NotificationCreator.call(
        actor: user,
        recipient: follower,
        notifiable: self,
        notification_type: "review.created",
        body: "#{user.username} posted a review for #{movie.title}",
        data: { movie_id: movie.id, review_id: id }
      )
    end
  end
end
