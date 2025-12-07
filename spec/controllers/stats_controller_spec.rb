require 'rails_helper'

RSpec.describe StatsController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:stats_service) { instance_double(StatsService) }

  let(:overview) do
    {
      total_movies: 10,
      total_hours: 1200,
      total_reviews: 5,
      total_rewatches: 2,
      genre_breakdown: { "Action" => 5, "Drama" => 3 }
    }
  end

  let(:top_contributors) do
    {
      top_genres: [ { name: "Action", count: 5 } ],
      top_directors: [ { name: "Christopher Nolan", count: 3 } ],
      top_actors: [ { name: "Leonardo DiCaprio", count: 2 } ]
    }
  end

  let(:trend_data) do
    {
      activity_trend: [ { month: "2024-01", count: 3 } ],
      rating_trend: [ { month: "2024-01", average_rating: 4.5 } ]
    }
  end

  let(:heatmap_years) { [ 2024, 2023 ] }
  let(:heatmap_data) { { "2024-01-01" => 1, "2024-01-02" => 0 } }
  let(:most_watched) do
    [
      { movie: build_stubbed(:movie, title: "Fav"), watch_count: 3, rewatch_count: 2 }
    ]
  end

    before do
      allow(controller).to receive(:authenticate_user!).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      allow(StatsService).to receive(:new).with(user).and_return(stats_service)
    end

  describe "GET #show" do
    before do
      allow(stats_service).to receive(:calculate_overview).and_return(overview)
      allow(stats_service).to receive(:calculate_top_contributors).and_return(top_contributors)
      allow(stats_service).to receive(:trend_years).and_return([ 2024 ])
      allow(stats_service).to receive(:calculate_trend_data).and_return(trend_data)
      allow(stats_service).to receive(:heatmap_years).and_return(heatmap_years)
      allow(stats_service).to receive(:calculate_heatmap_data).and_return(heatmap_data)
      allow(stats_service).to receive(:most_watched_movies).and_return(most_watched)
    end

    it "builds the service with the current user and renders the dashboard" do
      get :show
      expect(StatsService).to have_received(:new).with(user)
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    it "assigns the calculated stats" do
      get :show

      expect(assigns(:stats_service)).to eq(stats_service)
      expect(assigns(:overview)).to eq(overview)
      expect(assigns(:top_contributors)).to eq(top_contributors)
      expect(assigns(:trend_data)).to eq(trend_data)
      expect(assigns(:heatmap_years)).to eq(heatmap_years)
      expect(assigns(:heatmap_year)).to eq(heatmap_years.first)
      expect(assigns(:heatmap_data)).to eq(heatmap_data)
      expect(assigns(:most_watched)).to eq(most_watched)

      expect(stats_service).to have_received(:calculate_overview)
      expect(stats_service).to have_received(:calculate_top_contributors)
      expect(stats_service).to have_received(:calculate_trend_data)
      expect(stats_service).to have_received(:calculate_heatmap_data).with(year: heatmap_years.first)
      expect(stats_service).to have_received(:most_watched_movies).with(limit: 3)
    end

    it "uses the provided heatmap year when it is available" do
      allow(stats_service).to receive(:calculate_heatmap_data).and_return(heatmap_data)

      get :show, params: { heatmap_year: 2023 }

      expect(assigns(:heatmap_year)).to eq(2023)
      expect(stats_service).to have_received(:calculate_heatmap_data).with(year: 2023)
    end

    it "falls back to the first available heatmap year when the param is invalid" do
      get :show, params: { heatmap_year: 1900 }

      expect(assigns(:heatmap_year)).to eq(heatmap_years.first)
      expect(stats_service).to have_received(:calculate_heatmap_data).with(year: heatmap_years.first)
    end

    context "when no heatmap years are available" do
      let(:heatmap_years) { [] }

      it "defaults to the current year" do
        travel_to Date.new(2024, 6, 1) do
          get :show
        end

        expect(assigns(:heatmap_year)).to eq(2024)
        expect(stats_service).to have_received(:calculate_heatmap_data).with(year: 2024)
      end
    end
  end

  describe "GET #public" do
    let(:public_user) { create(:user, username: "cinephile") }
    let(:public_service) { instance_double(StatsService) }

    before do
      allow(StatsService).to receive(:new).with(public_user).and_return(public_service)
      allow(public_service).to receive(:calculate_overview).and_return(overview)
      allow(public_service).to receive(:calculate_top_contributors).and_return(top_contributors)
      allow(public_service).to receive(:trend_years).and_return([ 2024 ])
      allow(public_service).to receive(:calculate_trend_data).and_return(trend_data)
      allow(public_service).to receive(:heatmap_years).and_return(heatmap_years)
      allow(public_service).to receive(:calculate_heatmap_data).and_return(heatmap_data)
      allow(public_service).to receive(:most_watched_movies).and_return(most_watched)
    end

    it "renders the stats page without authentication and scopes to the requested user" do
      get :public, params: { username: public_user.username }

      expect(response).to have_http_status(:ok)
      expect(assigns(:stats_user)).to eq(public_user)
      expect(assigns(:overview)).to eq(overview)
      expect(assigns(:most_watched)).to eq(most_watched)
      expect(public_service).to have_received(:calculate_heatmap_data).with(year: heatmap_years.first)
    end

    it "raises when the user is not found" do
      expect { get :public, params: { username: "missing" } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
