class CreateNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :review_created, default: true
      t.boolean :review_voted, default: true
      t.boolean :user_followed, default: true

      t.timestamps
    end
  end
end
