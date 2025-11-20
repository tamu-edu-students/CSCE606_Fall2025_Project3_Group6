# frozen_string_literal: true

class AddConfirmableToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      # Confirmable fields — these do NOT exist yet
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email   # Required only if you're using reconfirmable
    end

    add_index :users, :confirmation_token, unique: true
  end
end
