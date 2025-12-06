class Notification < ApplicationRecord
  # The DB schema in this app originally used `user_id` for recipient.
  # Support both `user_id` and `recipient_id` for compatibility across environments.
  belongs_to :recipient, class_name: "User", foreign_key: (column_names.include?("recipient_id") ? "recipient_id" : "user_id")
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :notification_type, presence: true

  def self.unread
    if column_names.include?("read_at")
      where(read_at: nil)
    elsif column_names.include?("read")
      where(read: [ false, nil ])
    else
      where(nil)
    end
  end

  def self.read
    if column_names.include?("read_at")
      where.not(read_at: nil)
    elsif column_names.include?("read")
      where(read: true)
    else
      where("1 = 0")
    end
  end

  scope :recent, -> { order(created_at: :desc) }

  # Mark notification as read
  def mark_as_read!
    return if read?

    if has_attribute?(:read_at)
      update!(read_at: Time.current)
    elsif has_attribute?(:read)
      update!(read: true)
    else
      true
    end
  end

  # Mark notification as unread
  def mark_as_unread!
    return unless read?

    if has_attribute?(:read_at)
      update!(read_at: nil)
    elsif has_attribute?(:read)
      update!(read: false)
    else
      true
    end
  end

  def read?
    if has_attribute?(:read_at)
      read_at.present?
    elsif has_attribute?(:read)
      read == true
    else
      false
    end
  end

  def unread?
    !read?
  end

  # Mark notification as delivered (e.g. pushed to client)
  def mark_delivered!
    return if delivered?

    if has_attribute?(:delivered_at)
      update!(delivered_at: Time.current)
    else
      true
    end
  end

  def delivered?
    has_attribute?(:delivered_at) && delivered_at.present?
  end

  # Safe accessor for JSON payload
  def payload
    has_attribute?(:data) ? (data || {}) : {}
  end

  # Lightweight JSON representation used by controllers
  def as_json(options = {})
    allowed = %w[id actor_id notification_type body created_at]
    allowed << (column_names.include?("recipient_id") ? "recipient_id" : "user_id")
    allowed << "data" if column_names.include?("data")
    allowed << "read_at" if column_names.include?("read_at")
    allowed << "delivered_at" if column_names.include?("delivered_at")

    super({ only: allowed.map(&:to_sym) }.merge(options))
  end
end
