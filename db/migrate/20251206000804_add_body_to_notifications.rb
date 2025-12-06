class AddBodyToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :body, :text
  end
end
