class CreateWatchHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :watch_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :movie, null: false, foreign_key: true
      t.date :watched_on, null: false

      t.timestamps
    end

    add_index :watch_histories, [ :user_id, :movie_id, :watched_on ], name: "index_watch_histories_on_user_movie_watched_on"
  end
end
