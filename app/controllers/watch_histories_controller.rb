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
    movie = nil

    if params[:tmdb_id].present?
      movie = Movie.find_by(tmdb_id: params[:tmdb_id])
      if movie.nil?
        tmdb = TmdbService.new.movie_details(params[:tmdb_id])
        movie = Movie.find_or_create_from_tmdb(tmdb) if tmdb
      end
    elsif params[:movie_id].present?
      # When we get a local movie id from the form, look it up by primary key first
      movie = Movie.find_by(id: params[:movie_id]) || Movie.find_by(tmdb_id: params[:movie_id])
    end

    unless movie
      redirect_back fallback_location: root_path, alert: "Movie not found" and return
    end

    ensure_movie_runtime(movie)

    watched_on = params[:watched_on].presence || Date.current
    rating_param = params[:rating].presence
    rating_value = rating_param.to_i if rating_param.present? && rating_param.to_i.between?(1, 10)

    watch_history = current_user.watch_history || current_user.create_watch_history

    @watch_log = watch_history.watch_logs.new(movie: movie, watched_on: watched_on)
    @watch_log.incoming_rating = rating_value if rating_value

    if @watch_log.save
      notice_msg = "Logged as watched on #{watched_on}"
      notice_msg += " with rating #{rating_value}" if rating_value
      redirect_back fallback_location: movie_path(movie), notice: notice_msg
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

  private

  def ensure_movie_runtime(movie)
    return unless movie&.runtime.blank? && movie.tmdb_id.present?

    tmdb = tmdb_service.movie_details(movie.tmdb_id)
    runtime_val = tmdb.is_a?(Hash) ? tmdb["runtime"] || tmdb[:runtime] : nil
    return unless runtime_val.present? && runtime_val.to_i > 0

    movie.update(runtime: runtime_val.to_i, cached_at: Time.current)
  rescue StandardError => e
    Rails.logger.error("WatchHistoriesController#ensure_movie_runtime error: #{e.message}")
  end

  def tmdb_service
    @tmdb_service ||= TmdbService.new
  end
end
