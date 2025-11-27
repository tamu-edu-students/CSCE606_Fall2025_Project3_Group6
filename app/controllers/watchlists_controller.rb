class WatchlistsController < ApplicationController
  before_action :authenticate_user!

  def show
    @watchlist = current_user.watchlist || current_user.create_watchlist
    @items = @watchlist.watchlist_items.includes(:movie)
  end
end
