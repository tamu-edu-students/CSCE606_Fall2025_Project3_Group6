class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # ==================================================
  # ASSOCIATIONS
  # ==================================================
  # Basic
  has_many :reviews, dependent: :destroy
  has_many :votes, dependent: :destroy

  # Social (Follows)
  has_many :follows, foreign_key: :follower_id, dependent: :destroy
  has_many :followed_users, through: :follows, source: :followed
  has_many :following_users, foreign_key: :followed_id, class_name: "Follow", dependent: :destroy
  has_many :followers, through: :following_users, source: :follower

  # Social & Community (Lists, Logs) - From Feature Branch
  has_many :lists, dependent: :destroy
  has_many :logs, dependent: :destroy

  # Watchlist & History - From Main Branch
  has_one :watchlist, dependent: :destroy
  has_one :watch_history, dependent: :destroy

  # Notifications
  # The notifications table historically used `user_id` as the recipient column.
  has_many :notifications, foreign_key: (Notification.column_names.include?("recipient_id") ? :recipient_id : :user_id), dependent: :destroy
  has_one :notification_preference, dependent: :destroy

  # Stats
  has_one :user_stat, dependent: :destroy

  # ==================================================
  # CALLBACKS
  # ==================================================
  after_create :create_default_notification_preference

  # ==================================================
  # VALIDATIONS
  # ==================================================
  validate :password_complexity

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false, message: "is already taken" },
            length: { minimum: 3, maximum: 20 },
            format: {
              with: /\A[a-zA-Z0-9_]+\z/,
              message: "can only contain letters, numbers, and underscores"
            }

  # ==================================================
  # HELPER METHODS
  # ==================================================
  def following?(user)
    followed_users.include?(user)
  end

  def admin?
    id == 1
  end

  private

  def create_default_notification_preference
    create_notification_preference!(
      review_created: true,
      review_voted: true,
      user_followed: true,
      email_notifications: true
    )
  end

  def password_complexity
    return if password.blank?

    regex = /\A(?=.*[A-Z])(?=.*[\d\W]).{8,}\z/

    unless password =~ regex
      errors.add :password,
        "must be at least 8 characters long, include at least one uppercase letter, and include at least one number or special character."
    end
  end
end
