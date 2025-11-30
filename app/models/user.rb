class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :reviews, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :follows, foreign_key: :follower_id, dependent: :destroy
  has_many :followed_users, through: :follows, source: :followed
  has_many :following_users, foreign_key: :followed_id, class_name: "Follow", dependent: :destroy
  has_many :followers, through: :following_users, source: :follower
  has_many :logs, dependent: :destroy
  has_one :user_stat, dependent: :destroy

  validate :password_complexity

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 20 },
            format: {
              with: /\A[a-zA-Z0-9_]+\z/,
              message: "can only contain letters, numbers, and underscores"
            }


  private

  def password_complexity
    return if password.blank?

    regex = /\A(?=.*[A-Z])(?=.*[\d\W]).{8,}\z/

    unless password =~ regex
      errors.add :password,
        "must be at least 8 characters long, include at least one uppercase letter, and include at least one number or special character."
    end
  end

  def admin?
    id == 1
  end
end
