class RemoveMovieIdFromWatchlists < ActiveRecord::Migration[7.0]
  def up
    # remove foreign key to movies if it exists
    if foreign_key_exists?(:watchlists, :movies)
      remove_foreign_key :watchlists, :movies
    end

    # remove index on movie_id if present
    if index_name_exists?(:watchlists, "index_watchlists_on_movie_id")
      remove_index :watchlists, name: "index_watchlists_on_movie_id"
    elsif index_exists?(:watchlists, :movie_id)
      remove_index :watchlists, :movie_id
    end

    # finally remove the column (only if present)
    if column_exists?(:watchlists, :movie_id)
      remove_column :watchlists, :movie_id
    end
  end

  def down
    # add the column back (not restoring original FK automatically)
    unless column_exists?(:watchlists, :movie_id)
      add_column :watchlists, :movie_id, :bigint
      add_index :watchlists, :movie_id
      add_foreign_key :watchlists, :movies
    end
  end
end
