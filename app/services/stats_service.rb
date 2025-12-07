class StatsService
  def initialize(user, tmdb_service: TmdbService.new)
    @user = user
    @tmdb_service = tmdb_service
    @runtime_cache = {}
  end

  def calculate_overview
    logs = user_watch_logs.includes(:movie)
    legacy_logs = user_logs
    {
      total_movies: logs.select(:movie_id).distinct.count,
      total_hours: calculate_total_hours(logs),
      total_reviews: @user.reviews.count,
      total_rewatches: calculate_rewatch_count(logs, legacy_logs),
      genre_breakdown: calculate_genre_breakdown(logs),
      decade_breakdown: calculate_decade_breakdown(logs)
    }
  rescue StandardError => e
    Rails.logger.error("StatsService#calculate_overview error: #{e.message}")
    {
      total_movies: 0,
      total_hours: 0,
      total_reviews: 0,
      total_rewatches: 0,
      genre_breakdown: {},
      decade_breakdown: {}
    }
  end

  def calculate_top_contributors
    logs = user_watch_logs.includes(movie: [ :genres, movie_people: :person ])
    {
      top_genres: calculate_top_genres(logs),
      top_directors: calculate_top_directors(logs),
      top_actors: calculate_top_actors(logs)
    }
  end

  def most_watched_movies(limit: 5)
    logs = user_watch_logs.includes(:movie)
    legacy_rewatch_counts = user_logs.where(rewatch: true).group(:movie_id).count

    # Aggregate watches from watch history
    movie_counts = Hash.new { |h, k| h[k] = { count: 0, rewatch_count: 0 } }
    logs.each do |log|
      next unless log.movie
      movie_counts[log.movie_id][:count] += 1
    end

    # Fold in legacy rewatch flags (covers legacy rows and any synced ones)
    legacy_rewatch_counts.each do |movie_id, rewatch_count|
      movie_counts[movie_id][:rewatch_count] = [ movie_counts[movie_id][:rewatch_count], rewatch_count ].max
    end

    # Calculate rewatch count from repeated watch history entries
    movie_counts.each do |_movie_id, data|
      data[:rewatch_count] = [ data[:rewatch_count], data[:count] - 1 ].max
    end

    movie_ids = movie_counts.keys
    movies_by_id = Movie.where(id: movie_ids).index_by(&:id)

    movie_counts.map do |movie_id, data|
      movie = movies_by_id[movie_id]
      next unless movie
      {
        movie: movie,
        watch_count: data[:count],
        rewatch_count: data[:rewatch_count]
      }
    end.compact.sort_by { |row| [ -row[:rewatch_count], -row[:watch_count], row[:movie].title.to_s ] }.first(limit)
  rescue StandardError => e
    Rails.logger.error("StatsService#most_watched_movies error: #{e.message}")
    []
  end

  def calculate_trend_data(year: Date.current.year)
    logs = user_watch_logs.where.not(watched_on: nil)
      .where(watched_on: Date.new(year, 1, 1)..[ Date.new(year, 12, 31), Date.current ].min)
      .order(watched_on: :asc)
    {
      activity_trend: calculate_activity_trend(logs, year: year),
      rating_trend: calculate_rating_trend_from_watch_logs(logs, year: year)
    }
  end

  def calculate_heatmap_data(year: Date.current.year)
    logs = user_watch_logs.where.not(watched_on: nil)
    start_date = Date.new(year, 1, 1)
    end_date = [ Date.new(year, 12, 31), Date.today ].min
    logs = logs.where(watched_on: start_date..end_date)
    heatmap_hash = {}

    logs.each do |log|
      date = log.watched_on.to_date
      key = date.to_s
      heatmap_hash[key] ||= 0
      heatmap_hash[key] += 1
    end

    # 生成过去一年的日期范围（从今天往前推365天）
    # 填充所有日期（包括没有数据的日期）
    (start_date..end_date).each do |date|
      key = date.to_s
      heatmap_hash[key] ||= 0
    end

    heatmap_hash
  end

  def heatmap_years
    years = user_watch_logs.where.not(watched_on: nil)
      .pluck(Arel.sql("EXTRACT(YEAR FROM watched_on)::int")).uniq.sort.reverse
    filtered = years.select { |y| y >= Date.current.year - 4 }
    result = filtered.presence || last_five_years
    result.first(5)
  rescue StandardError
    [ Date.current.year ]
  end

  def trend_years
    last_five_years
  rescue StandardError
    [ Date.current.year ]
  end

  private

  def user_watch_logs
    # Prefer the user's watch history; fall back to user_id for resilience
    return WatchLog.none unless @user
    @user.watch_history&.watch_logs || WatchLog.where(user_id: @user.id)
  end

  def user_logs
    return Log.none unless @user
    @user.logs
  end

  def calculate_total_hours(logs)
    # Runtime is stored in minutes; sum per watch log so rewatches are counted.
    logs.includes(:movie).sum do |log|
      resolved_runtime(log.movie)
    end
  end

  def calculate_genre_breakdown(logs)
    genre_counts = Hash.new(0)

    logs.each do |log|
      log.movie.genres.each do |genre|
        genre_counts[genre.name] += 1
      end
    end

    genre_counts.sort_by { |_name, count| -count }.to_h
  end

  def calculate_decade_breakdown(logs)
    decade_counts = Hash.new(0)

    logs.each do |log|
      release_date = log.movie&.release_date
      year = if release_date.respond_to?(:year)
               release_date.year
      elsif release_date.present?
               Date.parse(release_date.to_s).year rescue nil
      end
      next unless year

      decade_start = (year / 10) * 10
      label = "#{decade_start}s"
      decade_counts[label] += 1
    end

    decade_counts.sort_by { |_name, count| -count }.to_h
  end

  def calculate_top_genres(logs, limit: 10)
    genre_counts = Hash.new(0)

    logs.each do |log|
      log.movie.genres.each do |genre|
        genre_counts[genre.name] += 1
      end
    end

    genre_counts.sort_by { |_name, count| -count }.first(limit).map do |name, count|
      { name: name, count: count }
    end
  end

  def calculate_top_directors(logs, limit: 10)
    director_counts = Hash.new { |h, k| h[k] = { count: 0, profile_path: nil } }

    # Get all movie IDs from logs
    movie_ids = logs.map(&:movie_id).uniq

    # Query all directors at once
    MoviePerson.where(movie_id: movie_ids, role: "director").includes(:person).each do |mp|
      entry = director_counts[mp.person.name]
      entry[:count] += 1
      entry[:profile_path] ||= mp.person&.profile_path
    end

    director_counts.sort_by { |_name, data| -data[:count] }.first(limit).map do |name, data|
      { name: name, count: data[:count], profile_path: data[:profile_path] }
    end
  end

  def calculate_top_actors(logs, limit: 10)
    actor_counts = Hash.new { |h, k| h[k] = { count: 0, profile_path: nil } }

    # Get all movie IDs from logs
    movie_ids = logs.map(&:movie_id).uniq

    # Query all actors at once
    MoviePerson.where(movie_id: movie_ids, role: "cast").includes(:person).each do |mp|
      entry = actor_counts[mp.person.name]
      entry[:count] += 1
      entry[:profile_path] ||= mp.person&.profile_path
    end

    actor_counts.sort_by { |_name, data| -data[:count] }.first(limit).map do |name, data|
      { name: name, count: data[:count], profile_path: data[:profile_path] }
    end
  end

  def calculate_activity_trend(logs, year:)
    start_window = Date.new(year, 1, 1)
    end_window = [ Date.new(year, 12, 31), Date.current.end_of_month ].min

    monthly_counts = Hash.new(0)
    logs.each do |log|
      next unless log.watched_on
      month_key = log.watched_on.strftime("%Y-%m")
      monthly_counts[month_key] += 1
    end

    results = []
    current_month = start_window
    while current_month <= end_window
      key = current_month.strftime("%Y-%m")
      results << { month: key, count: monthly_counts[key] || 0 }
      current_month = current_month.next_month
    end

    results
  end

  def calculate_rating_trend_from_watch_logs(logs, year:)
    monthly_data = {}
    return [] if logs.blank?

    # Load matching Log entries (where ratings live) keyed by movie/watched_on
    movie_ids = logs.map(&:movie_id).uniq
    dates = logs.map(&:watched_on).compact.uniq
    ratings = Log.where(user_id: @user.id, movie_id: movie_ids, watched_on: dates).where.not(rating: nil)
    ratings_index = ratings.each_with_object({}) do |log, h|
      h[[ log.movie_id, log.watched_on ]] = log.rating
    end

    logs.each do |watch_log|
      next unless watch_log.watched_on
      rating = ratings_index[[ watch_log.movie_id, watch_log.watched_on ]]
      next unless rating

      month_key = watch_log.watched_on.strftime("%Y-%m")
      monthly_data[month_key] ||= { total: 0, count: 0 }
      monthly_data[month_key][:total] += rating
      monthly_data[month_key][:count] += 1
    end

    # Ensure we include every month in the selected year (even zeros)
    (1..12).each do |m|
      key = Date.new(year, m, 1).strftime("%Y-%m")
      monthly_data[key] ||= { total: 0, count: 0 }
    end

    monthly_data.sort_by { |month, _data| month }.map do |month, data|
      avg_rating = data[:count] > 0 ? (data[:total].to_f / data[:count]).round(2) : 0
      { month: month, average_rating: avg_rating }
    end
  end

  def last_five_years
    current_year = Date.current.year
    (0..4).map { |offset| current_year - offset }
  end

  def calculate_rewatch_count(watch_logs, legacy_logs)
    rewatch_hash = watch_logs.group(:movie_id).having("COUNT(*) > 1").count
    watch_rewatches = rewatch_hash.values.sum { |count| count - 1 }
    legacy_rewatches = legacy_logs.where(rewatch: true).where.not(movie_id: rewatch_hash.keys).count
    watch_rewatches + legacy_rewatches
  end

  def resolved_runtime(movie)
    return 0 unless movie
    return movie.runtime if movie.runtime.present? && movie.runtime > 0

    update_runtime_from_tmdb(movie)
    movie.runtime.present? && movie.runtime > 0 ? movie.runtime : 0
  end

  def update_runtime_from_tmdb(movie)
    return if movie.tmdb_id.blank?

    # Avoid duplicate calls for the same movie id during one stats render
    if @runtime_cache.key?(movie.tmdb_id)
      cached_runtime = @runtime_cache[movie.tmdb_id]
      if cached_runtime.present? && cached_runtime > 0
        movie.update(runtime: cached_runtime, cached_at: Time.current) if movie.runtime != cached_runtime
        return cached_runtime
      end
    end

    details = @tmdb_service.movie_details(movie.tmdb_id.to_s)
    runtime_val = details.is_a?(Hash) ? details["runtime"] || details[:runtime] : nil
    return unless runtime_val.present? && runtime_val.to_i > 0

    runtime_int = runtime_val.to_i
    @runtime_cache[movie.tmdb_id] = runtime_int
    movie.update(runtime: runtime_int, cached_at: Time.current)
  rescue StandardError => e
    Rails.logger.error("StatsService#update_runtime_from_tmdb error: #{e.message}")
  end
end
