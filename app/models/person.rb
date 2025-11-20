class Person < ApplicationRecord
  has_many :movie_people, dependent: :destroy
  has_many :movies, through: :movie_people

  validates :name, presence: true
  validates :tmdb_id, uniqueness: true, allow_nil: true

  def self.find_or_create_from_tmdb(tmdb_id, name, profile_path = nil)
    find_or_create_by(tmdb_id: tmdb_id) do |person|
      person.name = name
      person.profile_path = profile_path
    end
  end

  def profile_url
    TmdbService.poster_url(profile_path)
  end
end
