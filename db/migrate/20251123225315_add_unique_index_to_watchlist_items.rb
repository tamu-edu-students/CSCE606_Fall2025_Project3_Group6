class AddUniqueIndexToWatchlistItems < ActiveRecord::Migration[8.0]
  def change
    add_index :watchlist_items, [ :watchlist_id, :movie_id ], unique: true
  end
end
