class AddTmdbIdToGenres < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:genres, :tmdb_id)
      add_column :genres, :tmdb_id, :integer
    end
    unless index_exists?(:genres, :tmdb_id)
      add_index :genres, :tmdb_id
    end
  end
end
