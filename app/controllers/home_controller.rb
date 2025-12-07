class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    if user_signed_in?
      following_ids = current_user.followed_user_ids

      # Activity Feed: Reviews and Logs from followed users
      recent_window = 14.days.ago
      @activities = []
      @activities += Review.where(user_id: following_ids).where("created_at >= ?", recent_window).includes(:user, :movie)
      @activities += Log.where(user_id: following_ids).where("created_at >= ?", recent_window).includes(:user, :movie)
      @activities += WatchLog.where(user_id: following_ids).where("created_at >= ?", recent_window).includes(:watch_history, :movie)
      @activities += Vote.where(user_id: following_ids).where("created_at >= ?", recent_window).includes(:user, review: :movie)
      @activities += Follow.where(follower_id: following_ids).where("created_at >= ?", recent_window).includes(:follower, :followed)

      @activities = @activities.sort_by(&:created_at).reverse

      # Simple pagination
      @page = params[:page].to_i
      @page = 1 if @page < 1
      per_page = 10
      @total_pages = (@activities.size / per_page.to_f).ceil
      @activities = @activities.slice((@page - 1) * per_page, per_page) || []
    end

    # Trending movies for guest view or sidebar
    @trending_movies = Movie.order(created_at: :desc).limit(4)
  end
end
