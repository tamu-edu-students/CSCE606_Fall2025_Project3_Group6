class AddConstraintsToNotifications < ActiveRecord::Migration[7.0]
  def change
    # Add missing foreign keys if they don't already exist.
    # Some environments may have `user_id` (generated earlier) instead of `recipient_id`.
    if column_exists?(:notifications, :recipient_id)
      add_foreign_key :notifications, :users, column: :recipient_id unless foreign_key_exists?(:notifications, column: :recipient_id, to_table: :users)
    elsif column_exists?(:notifications, :user_id)
      add_foreign_key :notifications, :users, column: :user_id unless foreign_key_exists?(:notifications, column: :user_id, to_table: :users)
    end

    if column_exists?(:notifications, :actor_id)
      add_foreign_key :notifications, :users, column: :actor_id unless foreign_key_exists?(:notifications, column: :actor_id, to_table: :users)
    end

    # Use Rails helper to set a JSONB default for the `data` column
    if column_exists?(:notifications, :data)
      change_column_default :notifications, :data, from: nil, to: {}
    end

    # Add useful indexes unless they already exist. Only add indexes when the columns exist.
    if column_exists?(:notifications, :recipient_id) && column_exists?(:notifications, :read_at)
      add_index :notifications, [ :recipient_id, :read_at ] unless index_exists?(:notifications, [ :recipient_id, :read_at ])
    elsif column_exists?(:notifications, :user_id) && column_exists?(:notifications, :read_at)
      add_index :notifications, [ :user_id, :read_at ] unless index_exists?(:notifications, [ :user_id, :read_at ])
    end

    if column_exists?(:notifications, :recipient_id) && column_exists?(:notifications, :notifiable_type) && column_exists?(:notifications, :notifiable_id)
      add_index :notifications, [ :recipient_id, :notifiable_type, :notifiable_id ], name: 'index_notifications_on_recipient_and_notifiable' unless index_exists?(:notifications, [ :recipient_id, :notifiable_type, :notifiable_id ], name: 'index_notifications_on_recipient_and_notifiable')
    elsif column_exists?(:notifications, :user_id) && column_exists?(:notifications, :notifiable_type) && column_exists?(:notifications, :notifiable_id)
      add_index :notifications, [ :user_id, :notifiable_type, :notifiable_id ], name: 'index_notifications_on_recipient_and_notifiable' unless index_exists?(:notifications, [ :user_id, :notifiable_type, :notifiable_id ], name: 'index_notifications_on_recipient_and_notifiable')
    end
  end
end
