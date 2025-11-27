require 'rails_helper'

RSpec.describe "WatchHistories", type: :request do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  describe "GET /index" do
    it "shows the user's watch logs" do
      user = create(:user)
      login_as(user, scope: :user)
      history = create(:watch_history, user: user)
      log = create(:watch_log, watch_history: history)

      get watch_histories_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(log.movie.title)
    end

    it "accepts a query param without error" do
      user = create(:user)
      login_as(user, scope: :user)
      history = create(:watch_history, user: user)
      m1 = create(:movie, title: "FindMe")
      m2 = create(:movie, title: "Other")
      create(:watch_log, watch_history: history, movie: m1)
      create(:watch_log, watch_history: history, movie: m2)

      get watch_histories_path, params: { q: 'Find' }
      expect(response).to have_http_status(:success)
    end

    it "filters by watched_from and watched_to dates" do
      user = create(:user)
      login_as(user, scope: :user)
      history = create(:watch_history, user: user)
      m1 = create(:movie, title: "Old")
      m2 = create(:movie, title: "New")
      create(:watch_log, watch_history: history, movie: m1, watched_on: Date.new(2020, 1, 1))
      create(:watch_log, watch_history: history, movie: m2, watched_on: Date.new(2022, 1, 1))

      get watch_histories_path, params: { watched_from: '2021-01-01', watched_to: '2023-01-01' }
      expect(response.body).to include('New')
      expect(response.body).not_to include('Old')
    end

    it "sorts by name and watched date" do
      user = create(:user)
      login_as(user, scope: :user)
      history = create(:watch_history, user: user)
      m1 = create(:movie, title: "A Movie")
      m2 = create(:movie, title: "Z Movie")
      create(:watch_log, watch_history: history, movie: m2, watched_on: Date.new(2022, 1, 2))
      create(:watch_log, watch_history: history, movie: m1, watched_on: Date.new(2022, 1, 1))

      get watch_histories_path, params: { sort: 'name_asc' }
      expect(response.body.index('A Movie')).to be < response.body.index('Z Movie')

      get watch_histories_path, params: { sort: 'watched_asc' }
      expect(response.body.index('A Movie')).to be < response.body.index('Z Movie')
    end
  end

  describe "POST /create" do
    it "creates a watch log with movie_id" do
      user = create(:user)
      login_as(user, scope: :user)
      movie = create(:movie)

      expect {
        post watch_histories_path, params: { movie_id: movie.id, watched_on: Date.yesterday }
      }.to change(WatchLog, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "creates a watch log using tmdb_id by fetching from TMDB" do
      user = create(:user, username: "u#{SecureRandom.hex(6)}")
      login_as(user, scope: :user)
      tmdb_id = 7_777
      tmdb_data = {
        "id" => tmdb_id,
        "title" => "From TMDB",
        "overview" => "x",
        "poster_path" => "/p.png",
        "release_date" => "2019-01-01",
        "runtime" => 90,
        "popularity" => 1.0
      }
      allow_any_instance_of(TmdbService).to receive(:movie_details).with(tmdb_id.to_s).and_return(tmdb_data)

      expect {
        post watch_histories_path, params: { tmdb_id: tmdb_id, watched_on: Date.yesterday }
      }.to change(Movie, :count).by(1).and change(WatchLog, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "redirects to root when tmdb_id invalid" do
      user = create(:user)
      login_as(user, scope: :user)
      allow_any_instance_of(TmdbService).to receive(:movie_details).and_return(nil)

      post watch_histories_path, params: { tmdb_id: 'bad' }
      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      movie = create(:movie)
      post watch_histories_path, params: { movie_id: movie.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /destroy" do
    it "deletes the watch log" do
      user = create(:user)
      login_as(user, scope: :user)
      history = create(:watch_history, user: user)
      log = create(:watch_log, watch_history: history)

      expect {
        delete watch_history_path(log.id)
      }.to change(WatchLog, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end
end
