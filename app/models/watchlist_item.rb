class WatchlistItem < ApplicationRecord
  belongs_to :watchlist
  belongs_to :movie
end
