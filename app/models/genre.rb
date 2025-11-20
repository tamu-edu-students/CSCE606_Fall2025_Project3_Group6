class Genre < ApplicationRecord
  has_many :movie_genres, dependent: :destroy
  has_many :movies, through: :movie_genres

  validates :name, presence: true
  validates :tmdb_id, uniqueness: true, allow_nil: true, if: -> { tmdb_id.present? }

  def self.find_or_create_from_tmdb(tmdb_id, name)
    find_or_create_by(tmdb_id: tmdb_id) do |genre|
      genre.name = name
    end
  end
end
