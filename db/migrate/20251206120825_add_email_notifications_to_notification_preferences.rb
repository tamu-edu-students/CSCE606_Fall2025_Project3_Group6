class AddEmailNotificationsToNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    add_column :notification_preferences, :email_notifications, :boolean, default: true

    # backfill existing rows to true for safety
    reversible do |dir|
      dir.up do
        NotificationPreference.update_all(email_notifications: true)
      end
    end
  end
end
