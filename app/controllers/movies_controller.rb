class MoviesController < ApplicationController
  before_action :set_tmdb_service

  def index
    @query = params[:query]&.strip
    @page = params[:page]&.to_i || 1
    @genre_filter = params[:genre]&.to_i
    @decade_filter = params[:decade]&.to_i
    @sort_by = params[:sort_by] || "popularity"

    if @query.present?
      search_results = @tmdb_service.search_movies(@query, page: @page)

      if search_results["error"]
        @error = search_results["error"]
        @movies = []
        @total_pages = 0
        @total_results = 0
      else
        @movies = search_results["results"] || []
        @total_pages = search_results["total_pages"] || 0
        @total_results = search_results["total_results"] || 0

        # Apply filters
        @movies = apply_filters(@movies)
        # Apply sorting
        @movies = apply_sorting(@movies)

        # Sync movies to database
        sync_movies_to_db(@movies)
      end
    else
      @movies = []
      @total_pages = 0
      @total_results = 0
      @error = nil
    end

    # Get genres for filter dropdown
    genres_data = @tmdb_service.genres
    @genres = genres_data["genres"] || []
  end

  def show
    @movie = Movie.find_by(tmdb_id: params[:id])

    # Fetch from TMDb if not cached or cache expired
    unless @movie&.cached?
      tmdb_data = @tmdb_service.movie_details(params[:id])
      if tmdb_data
        @movie = Movie.find_or_create_from_tmdb(tmdb_data)
        sync_movie_details(@movie, tmdb_data)
      else
        @movie = nil
        @error = "Movie not found"
      end
    end

    # Get similar movies
    @similar_movies = []
    if @movie
      similar_data = @tmdb_service.similar_movies(@movie.tmdb_id)
      if similar_data["error"]
        @similar_movies = similar_data
      else
        @similar_movies = similar_data["results"] || []
        sync_movies_to_db(@similar_movies) if @similar_movies.is_a?(Array)
      end
    end
  end

  def search
    query = params[:query]&.strip

    if query.blank?
      render json: { error: "Please enter a search query" }, status: :unprocessable_entity
      return
    end

    results = @tmdb_service.search_movies(query, page: params[:page] || 1)
    render json: results
  end

  private

  def set_tmdb_service
    @tmdb_service = TmdbService.new
  end

  def apply_filters(movies)
    filtered = movies

    # Filter by genre
    if @genre_filter.present?
      genre = Genre.find_by(tmdb_id: @genre_filter)
      if genre
        filtered = filtered.select do |movie_data|
          genre_ids = movie_data["genre_ids"] || []
          genre_ids.include?(@genre_filter)
        end
      end
    end

    # Filter by decade
    if @decade_filter.present?
        filtered = filtered.select do |movie_data|
          release_date = movie_data["release_date"]
          next false unless release_date
          begin
            year = Date.parse(release_date).year
          rescue ArgumentError, TypeError
            next false
          end
          next false unless year
          (year / 10) * 10 == @decade_filter
        end
    end

    filtered
  end

  def apply_sorting(movies)
    case @sort_by
    when "popularity"
      movies.sort_by { |m| -(m["popularity"] || 0) }
    when "rating"
      movies.sort_by { |m| -(m["vote_average"] || 0) }
    when "release_date"
      movies.sort_by do |m|
        release_date = m["release_date"]
        if release_date
          begin
            Date.parse(release_date)
          rescue ArgumentError, TypeError
            Date.new(1900, 1, 1)
          end
        else
          Date.new(1900, 1, 1)
        end
      end.reverse
    else
      movies
    end
  end

  def sync_movies_to_db(movies_data)
    movies_data.each do |movie_data|
      Movie.find_or_create_from_tmdb(movie_data)
    end
  end

  def sync_movie_details(movie, tmdb_data)
    return unless movie && tmdb_data

    # Sync genres
    if tmdb_data["genres"]
      movie.movie_genres.destroy_all
      tmdb_data["genres"].each do |genre_data|
        genre = Genre.find_or_create_from_tmdb(genre_data["id"], genre_data["name"])
        MovieGenre.find_or_create_by(movie: movie, genre: genre)
      end
    end

    # Sync cast and crew
    if tmdb_data["credits"]
      movie.movie_people.destroy_all

      # Cast
      if tmdb_data["credits"]["cast"]
        tmdb_data["credits"]["cast"].first(10).each do |cast_data|
          person = Person.find_or_create_from_tmdb(
            cast_data["id"],
            cast_data["name"],
            cast_data["profile_path"]
          )
          MoviePerson.find_or_create_by(
            movie: movie,
            person: person,
            role: "cast",
            character: cast_data["character"]
          )
        end
      end

      # Crew (directors)
      if tmdb_data["credits"]["crew"]
        directors = tmdb_data["credits"]["crew"].select { |c| c["job"] == "Director" }
        directors.first(5).each do |crew_data|
          person = Person.find_or_create_from_tmdb(
            crew_data["id"],
            crew_data["name"],
            crew_data["profile_path"]
          )
          MoviePerson.find_or_create_by(
            movie: movie,
            person: person,
            role: "director"
          )
        end
      end
    end
  end
end
