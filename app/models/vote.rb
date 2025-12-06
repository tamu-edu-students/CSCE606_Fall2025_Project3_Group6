class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :review

  validates :value, inclusion: { in: [ 1, -1 ] }
  validates :user_id, uniqueness: { scope: :review_id }

  after_commit :update_review_score
  after_create :notify_review_author

  private

  def update_review_score
    review.update_score!
  end

  def notify_review_author
    return if review.user == user # Don't notify if user voted on their own review

    vote_type = value == 1 ? "liked" : "disliked"
    NotificationCreator.call(
      actor: user,
      recipient: review.user,
      notifiable: review,
      notification_type: "review.voted",
      body: "#{user.username} #{vote_type} your review of #{review.movie.title}"
    )
  end
end
