class NotificationCreator
  # Simple service to create a notification.
  # Usage:
  # NotificationCreator.call(actor: current_user, recipient: user, notifiable: review, notification_type: 'review.created', body: '...')
  def self.call(actor:, recipient:, notifiable: nil, notification_type:, body: nil, data: {})
    return if recipient.blank?

    # Check if user wants this notification type
    # Map user.followed and user.unfollowed to the same preference key
    preference_key = if notification_type == "user.unfollowed"
                       "user_followed"
    else
                       notification_type.gsub(".", "_")
    end
    preference = recipient.notification_preference

    # If preference exists and is disabled, don't create notification
    # If preference doesn't exist, allow notification (default behavior)
    if preference&.respond_to?(preference_key)
      return unless preference.send(preference_key)
    end

    attrs = build_attributes(actor, recipient, notifiable, notification_type, body, data)
    notification = Notification.create!(attrs)

    # Push fresh dropdown and list HTML to the recipient in real time
    Turbo::StreamsChannel.broadcast_replace_to(
      [ recipient, :notifications ],
      target: "notifications-dropdown",
      partial: "shared/notifications_dropdown",
      locals: { user: recipient, signed_in: true }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      [ recipient, :notifications ],
      target: "notifications-list",
      partial: "notifications/list",
      locals: { notifications: recipient.notifications.recent }
    )

    # Send email notification if body is present
    if body.present? && recipient.notification_preference&.email_notifications?
      NotificationMailer.send_notification(recipient, body).deliver_later
    end

    notification
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "Failed to create notification: #{e.record.errors.full_messages.join(', ')}"
    nil
  end

  private

  def self.build_attributes(actor, recipient, notifiable, notification_type, body, data)
    attrs = {}

    # Only set attributes that exist in the schema
    attrs[:notification_type] = notification_type if Notification.column_names.include?("notification_type")
    attrs[:body] = body if Notification.column_names.include?("body") && body.present?

    # Use the correct foreign key column name based on schema
    if Notification.column_names.include?("recipient_id")
      attrs[:recipient_id] = recipient.id
    else
      attrs[:user_id] = recipient.id
    end

    # Set actor if schema supports it
    attrs[:actor_id] = actor.id if actor.present? && Notification.column_names.include?("actor_id")

    # Set notifiable if schema supports it
    if notifiable.present?
      attrs[:notifiable_type] = notifiable.class.name if Notification.column_names.include?("notifiable_type")
      attrs[:notifiable_id] = notifiable.id if Notification.column_names.include?("notifiable_id")
    end

    # Set data if schema supports it
    attrs[:data] = data if Notification.column_names.include?("data") && data.present?

    attrs
  end
end
