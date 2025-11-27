class WatchlistItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    watchlist = current_user.watchlist || current_user.create_watchlist

    # params[:movie_id] may be a local Movie id or a TMDB id from API results.
    movie = find_or_create_movie_from_param(params[:movie_id])

    unless movie
      redirect_back fallback_location: movies_path, alert: "Could not find movie." and return
    end

    item = watchlist.watchlist_items.find_or_initialize_by(movie_id: movie.id)
    if item.new_record?
      item.save
      redirect_back fallback_location: watchlist_path, notice: "Added to watchlist."
    else
      redirect_back fallback_location: watchlist_path, notice: "Already in watchlist."
    end
  end

  def destroy
    item = current_user.watchlist&.watchlist_items&.find_by(id: params[:id])
    if item
      movie = item.movie
      if item.destroy
        # Provide an undo link that posts to the restore action
        undo_link = view_context.link_to("Undo", restore_watchlist_items_path(movie_id: movie.id), method: :post)
        redirect_back fallback_location: watchlist_path, notice: "Removed from #{movie.title} watchlist. "
      else
        redirect_back fallback_location: watchlist_path, alert: "Could not remove item."
      end
    else
      redirect_back fallback_location: watchlist_path, alert: "Item not found."
    end
  end

  # POST /watchlist_items/restore
  def restore
    watchlist = current_user.watchlist || current_user.create_watchlist
    movie = find_or_create_movie_from_param(params[:movie_id])
    unless movie
      redirect_back fallback_location: watchlist_path, alert: "Could not restore movie." and return
    end

    item = watchlist.watchlist_items.find_or_initialize_by(movie_id: movie.id)
    if item.new_record?
      item.save
      redirect_back fallback_location: watchlist_path, notice: "Movie restored to watchlist."
    else
      redirect_back fallback_location: watchlist_path, notice: "Movie already in watchlist."
    end
  end

  private

  def find_or_create_movie_from_param(param_id)
    return nil if param_id.blank?

    # Try to find by local id first
    movie = Movie.find_by(id: param_id)
    return movie if movie

    # Then try to find by tmdb_id
    movie = Movie.find_by(tmdb_id: param_id)
    return movie if movie

    # Otherwise try to fetch details from TMDB and create the movie locally
    tmdb = TmdbService.new.movie_details(param_id)
    return nil unless tmdb

    Movie.find_or_create_from_tmdb(tmdb)
  end
end
