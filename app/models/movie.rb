class Movie < ApplicationRecord
  has_many :movie_genres, dependent: :destroy
  has_many :genres, through: :movie_genres
  has_many :movie_people, dependent: :destroy
  has_many :people, through: :movie_people
  has_many :reviews, dependent: :destroy
  has_many :logs, dependent: :destroy
  has_many :watch_logs, dependent: :destroy

  validates :tmdb_id, presence: true, uniqueness: true

  scope :cached, -> { where.not(cached_at: nil) }
  scope :recently_cached, -> { where("cached_at > ?", 24.hours.ago) }

  def to_param
    tmdb_id.to_s
  end

  def self.find_or_create_from_tmdb(tmdb_data)
    return nil if tmdb_data.blank?

    movie = find_or_initialize_by(tmdb_id: tmdb_data["id"])
    movie.assign_attributes(
      title: tmdb_data["title"],
      overview: tmdb_data["overview"],
      poster_path: tmdb_data["poster_path"],
      release_date: tmdb_data["release_date"],
      runtime: tmdb_data["runtime"],
      popularity: tmdb_data["popularity"] || 0,
      cached_at: Time.current
    )
    movie.save!
    movie
  end

  def poster_url
    TmdbService.poster_url(poster_path)
  end

  def release_year
    return nil unless release_date
    release_date.year
  end

  def decade
    return nil unless release_year
    (release_year / 10) * 10
  end

  def cached?
    cached_at.present? && cached_at > 24.hours.ago
  end
end
