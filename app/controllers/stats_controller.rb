class StatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @stats_service = StatsService.new(current_user)
    @overview = @stats_service.calculate_overview
    @top_contributors = @stats_service.calculate_top_contributors
    @trend_data = @stats_service.calculate_trend_data
    @heatmap_data = @stats_service.calculate_heatmap_data
  end
end
