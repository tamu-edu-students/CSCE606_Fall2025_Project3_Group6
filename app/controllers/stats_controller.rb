class StatsController < ApplicationController
  before_action :authenticate_user!, only: :show

  def show
    @stats_user = current_user
    build_stats_for(@stats_user)
  end

  # Public, user-specific stats page
  def public
    @stats_user = User.find_by!(username: params[:username])
    build_stats_for(@stats_user)
    render :show
  end

  private

  def build_stats_for(user)
    @stats_service = StatsService.new(user)
    @overview = @stats_service.calculate_overview
    @top_contributors = @stats_service.calculate_top_contributors
    @most_watched = @stats_service.most_watched_movies(limit: 3)

    @trend_years = @stats_service.trend_years
    @trend_year = selected_year(@trend_years, params[:trend_year])
    @trend_data = @stats_service.calculate_trend_data(year: @trend_year)

    @heatmap_years = @stats_service.heatmap_years
    @heatmap_year = selected_year(@heatmap_years, params[:heatmap_year])
    @heatmap_data = @stats_service.calculate_heatmap_data(year: @heatmap_year)
  end

  def selected_year(available_years, param_value)
    year_param = param_value.to_i
    return year_param if available_years.include?(year_param)
    available_years.first || Date.current.year
  end
end
