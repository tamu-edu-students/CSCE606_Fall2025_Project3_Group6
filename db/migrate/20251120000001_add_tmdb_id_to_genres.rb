class AddTmdbIdToGenres < ActiveRecord::Migration[8.0]
  def change
    add_column :genres, :tmdb_id, :integer
    add_index :genres, :tmdb_id
  end
end
