class RenameWatchHistoriesToWatchLogsAndCreateWatchHistories < ActiveRecord::Migration[7.0]
  def change
    if table_exists?(:watch_histories) && !table_exists?(:watch_logs)
      rename_table :watch_histories, :watch_logs
      # recreate index with a new name (safe if it already exists)
      if index_name_exists?(:watch_logs, "index_watch_histories_on_user_movie_watched_on")
        rename_index :watch_logs, "index_watch_histories_on_user_movie_watched_on", "index_watch_logs_on_user_movie_watched_on"
      else
        add_index :watch_logs, [ :user_id, :movie_id, :watched_on ], name: "index_watch_logs_on_user_movie_watched_on"
      end
    end

    create_table :watch_histories do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
