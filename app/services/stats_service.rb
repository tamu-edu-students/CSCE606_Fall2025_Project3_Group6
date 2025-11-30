class StatsService
  def initialize(user)
    @user = user
  end

  def calculate_overview
    logs = @user.logs.includes(:movie)
    {
      total_movies: logs.select(:movie_id).distinct.count,
      total_hours: calculate_total_hours(logs),
      total_reviews: @user.reviews.count,
      total_rewatches: logs.where(rewatch: true).count,
      genre_breakdown: calculate_genre_breakdown(logs)
    }
  rescue StandardError => e
    Rails.logger.error("StatsService#calculate_overview error: #{e.message}")
    {
      total_movies: 0,
      total_hours: 0,
      total_reviews: 0,
      total_rewatches: 0,
      genre_breakdown: {}
    }
  end

  def calculate_top_contributors
    logs = @user.logs.includes(movie: [ :genres, movie_people: :person ])
    {
      top_genres: calculate_top_genres(logs),
      top_directors: calculate_top_directors(logs),
      top_actors: calculate_top_actors(logs)
    }
  end

  def calculate_trend_data
    logs = @user.logs.where.not(watched_on: nil).order(watched_on: :asc)
    {
      activity_trend: calculate_activity_trend(logs),
      rating_trend: calculate_rating_trend(logs)
    }
  end

  def calculate_heatmap_data
    logs = @user.logs.where.not(watched_on: nil)
    heatmap_hash = {}

    logs.each do |log|
      date = log.watched_on.to_date
      key = date.to_s
      heatmap_hash[key] ||= 0
      heatmap_hash[key] += 1
    end

    # 生成过去一年的日期范围（从今天往前推365天）
    end_date = Date.today
    start_date = 365.days.ago.to_date

    # 填充所有日期（包括没有数据的日期）
    (start_date..end_date).each do |date|
      key = date.to_s
      heatmap_hash[key] ||= 0
    end

    heatmap_hash
  end

  private

  def calculate_total_hours(logs)
    # Runtime is stored in minutes, return in minutes (will be converted to hours in view)
    # Use pluck to avoid loading all movie objects
    movie_ids = logs.pluck(:movie_id)
    Movie.where(id: movie_ids).sum(:runtime) || 0
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
    director_counts = Hash.new(0)

    # Get all movie IDs from logs
    movie_ids = logs.map(&:movie_id).uniq

    # Query all directors at once
    MoviePerson.where(movie_id: movie_ids, role: "director").includes(:person).each do |mp|
      director_counts[mp.person.name] += 1
    end

    director_counts.sort_by { |_name, count| -count }.first(limit).map do |name, count|
      { name: name, count: count }
    end
  end

  def calculate_top_actors(logs, limit: 10)
    actor_counts = Hash.new(0)

    # Get all movie IDs from logs
    movie_ids = logs.map(&:movie_id).uniq

    # Query all actors at once
    MoviePerson.where(movie_id: movie_ids, role: "cast").includes(:person).each do |mp|
      actor_counts[mp.person.name] += 1
    end

    actor_counts.sort_by { |_name, count| -count }.first(limit).map do |name, count|
      { name: name, count: count }
    end
  end

  def calculate_activity_trend(logs)
    monthly_data = Hash.new(0)

    logs.each do |log|
      next unless log.watched_on
      month_key = log.watched_on.strftime("%Y-%m")
      monthly_data[month_key] += 1
    end

    monthly_data.sort_by { |month, _count| month }.map do |month, count|
      { month: month, count: count }
    end
  end

  def calculate_rating_trend(logs)
    monthly_data = {}

    logs.where.not(rating: nil).each do |log|
      next unless log.watched_on && log.rating
      month_key = log.watched_on.strftime("%Y-%m")

      monthly_data[month_key] ||= { total: 0, count: 0 }
      monthly_data[month_key][:total] += log.rating
      monthly_data[month_key][:count] += 1
    end

    monthly_data.sort_by { |month, _data| month }.map do |month, data|
      avg_rating = data[:count] > 0 ? (data[:total].to_f / data[:count]).round(2) : 0
      { month: month, average_rating: avg_rating }
    end
  end
end
