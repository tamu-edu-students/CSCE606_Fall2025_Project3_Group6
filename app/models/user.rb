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

  # Stats
  has_one :user_stat, dependent: :destroy

  # ==================================================
  # VALIDATIONS
  # ==================================================
  validate :password_complexity

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
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

  def password_complexity
    return if password.blank?

    regex = /\A(?=.*[A-Z])(?=.*[\d\W]).{8,}\z/

    unless password =~ regex
      errors.add :password,
        "must be at least 8 characters long, include at least one uppercase letter, and include at least one number or special character."
    end
  end
end
