class WatchHistoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @watch_history = current_user.watch_history || current_user.create_watch_history

    # base relation
    logs = @watch_history.watch_logs.includes(:movie)

    # filtering by movie title (case-insensitive)
    if params[:q].present?
      q = params[:q].strip
      # safe parameter binding
      logs = logs.joins(:movie).where("movies.title ILIKE ?", "%\#{q}%")
    end

    # filter by watched date range (optional)
    if params[:watched_from].present?
      begin
        from = Date.parse(params[:watched_from])
        logs = logs.where("watched_on >= ?", from)
      rescue ArgumentError
        # ignore invalid date
      end
    end

    if params[:watched_to].present?
      begin
        to = Date.parse(params[:watched_to])
        logs = logs.where("watched_on <= ?", to)
      rescue ArgumentError
        # ignore invalid date
      end
    end

    # sorting - allow only specific options
    case params[:sort]
    when "watched_asc"
      logs = logs.order(watched_on: :asc)
    when "watched_desc"
      logs = logs.order(watched_on: :desc)
    when "name_asc"
      logs = logs.joins(:movie).order("movies.title ASC")
    when "name_desc"
      logs = logs.joins(:movie).order("movies.title DESC")
    else
      # default to watched_on desc
      logs = logs.order(watched_on: :desc)
    end

    @watch_logs = logs
  end

  def create
    # Prefer an explicit TMDB id if provided, otherwise accept a local movie id
    search_param = params[:tmdb_id].presence || params[:movie_id]

    movie = Movie.find_by(tmdb_id: search_param) || Movie.find_by(id: search_param)

    # If a tmdb_id was provided and no local movie exists, try fetching from TMDB
    if movie.nil? && params[:tmdb_id].present?
      tmdb = TmdbService.new.movie_details(params[:tmdb_id])
      movie = Movie.find_or_create_from_tmdb(tmdb) if tmdb
    end

    unless movie
      redirect_back fallback_location: root_path, alert: "Movie not found" and return
    end

    watched_on = params[:watched_on].presence || Date.current

    watch_history = current_user.watch_history || current_user.create_watch_history

    @watch_log = watch_history.watch_logs.new(movie: movie, watched_on: watched_on)

    if @watch_log.save
      redirect_back fallback_location: movie_path(movie), notice: "Logged as watched on #{watched_on}"
    else
      redirect_back fallback_location: movie_path(movie), alert: @watch_log.errors.full_messages.to_sentence
    end
  end

  def destroy
    watch_history = current_user.watch_history
    @watch_log = watch_history&.watch_logs&.find_by(id: params[:id])
    if @watch_log
      @watch_log.destroy
      redirect_to watch_histories_path, notice: "Removed from watch history"
    else
      redirect_to watch_histories_path, alert: "Watch history entry not found"
    end
  end
end
