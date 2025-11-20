class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

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
end
