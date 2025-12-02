class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    if user_signed_in?
      following_ids = current_user.followed_user_ids

      # Activity Feed: Reviews and Logs from followed users
      @activities = []
      @activities += Review.where(user_id: following_ids).includes(:user, :movie)
      @activities += Log.where(user_id: following_ids).includes(:user, :movie)

      @activities = @activities.sort_by(&:created_at).reverse
    end

    # Trending movies for guest view or sidebar
    @trending_movies = Movie.order(created_at: :desc).limit(4)
  end
end
