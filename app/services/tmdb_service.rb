class TmdbService
  BASE_URL = "https://api.themoviedb.org/3"
  IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500"

  def initialize
    @api_key = ENV.fetch("TMDB_API_KEY", "")
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def search_movies(query, page: 1)
    return { results: [], total_pages: 0, total_results: 0 } if query.blank?

    cache_key = "tmdb_search_#{query.downcase}_page_#{page}"
    cached = Rails.cache.read(cache_key)

    return cached if cached.present?

    begin
      response = @conn.get("/search/movie") do |req|
        req.params[:api_key] = @api_key
        req.params[:query] = query
        req.params[:page] = page
      end

      if response.status == 429
        # Rate limit exceeded - return cached results if available
        stale_cache = Rails.cache.read(cache_key)
        return stale_cache if stale_cache.present?

        return {
          results: [],
          total_pages: 0,
          total_results: 0,
          error: "Rate limit exceeded. Please try again later."
        }
      end

      if response.success?
        data = response.body
        Rails.cache.write(cache_key, data, expires_in: 1.hour)
        data
      else
        { results: [], total_pages: 0, total_results: 0, error: "API request failed" }
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      # Return cached results if available, even if expired
      stale_cache = Rails.cache.read(cache_key)
      return stale_cache if stale_cache.present?

      { results: [], total_pages: 0, total_results: 0, error: "Connection error. Please try again later." }
    rescue StandardError => e
      Rails.logger.error "TMDb API Error: #{e.message}"
      { results: [], total_pages: 0, total_results: 0, error: "An error occurred" }
    end
  end

  def movie_details(tmdb_id)
    return nil if tmdb_id.blank?

    cache_key = "tmdb_movie_#{tmdb_id}"
    cached = Rails.cache.read(cache_key)

    return cached if cached.present?

    begin
      response = @conn.get("/movie/#{tmdb_id}") do |req|
        req.params[:api_key] = @api_key
        req.params[:append_to_response] = "credits,videos"
      end

      if response.success?
        data = response.body
        Rails.cache.write(cache_key, data, expires_in: 24.hours)
        data
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error "TMDb API Error for movie #{tmdb_id}: #{e.message}"
      nil
    end
  end

  def similar_movies(tmdb_id, page: 1)
    return { results: [], total_pages: 0 } if tmdb_id.blank?

    cache_key = "tmdb_similar_#{tmdb_id}_page_#{page}"
    cached = Rails.cache.read(cache_key)

    return cached if cached.present?

    begin
      response = @conn.get("/movie/#{tmdb_id}/similar") do |req|
        req.params[:api_key] = @api_key
        req.params[:page] = page
      end

      if response.success?
        data = response.body
        Rails.cache.write(cache_key, data, expires_in: 24.hours)
        data
      else
        { results: [], total_pages: 0, error: "API request failed" }
      end
    rescue StandardError => e
      Rails.logger.error "TMDb API Error for similar movies #{tmdb_id}: #{e.message}"
      { results: [], total_pages: 0, error: "An error occurred" }
    end
  end

  def genres
    cache_key = "tmdb_genres"
    cached = Rails.cache.read(cache_key)

    return cached if cached.present?

    begin
      response = @conn.get("/genre/movie/list") do |req|
        req.params[:api_key] = @api_key
      end

      if response.success?
        data = response.body
        Rails.cache.write(cache_key, data, expires_in: 7.days)
        data
      else
        { genres: [] }
      end
    rescue StandardError => e
      Rails.logger.error "TMDb API Error for genres: #{e.message}"
      { genres: [] }
    end
  end

  def self.poster_url(poster_path)
    return nil if poster_path.blank?
    "#{IMAGE_BASE_URL}#{poster_path}"
  end
end
