require 'rails_helper'
include Warden::Test::Helpers

RSpec.configure do |config|
  config.after(:each) { Warden.test_reset! }
end

RSpec.describe "WatchlistItems", type: :request do
  describe "POST /watchlist_items (create)" do
    it "adds a local movie to the user's watchlist" do
      user = create(:user)
      login_as(user, scope: :user)
      movie = create(:movie)

      expect {
        post "/watchlist_items", params: { movie_id: movie.id }
      }.to change { user.watchlist&.watchlist_items&.count.to_i }.by(1)

      expect(response).to have_http_status(:redirect)
    end

    it "creates a movie from tmdb id when not present locally" do
      user = create(:user, username: "u#{SecureRandom.hex(6)}")
      login_as(user, scope: :user)

      tmdb_id = 9_999
      tmdb_data = {
        "id" => tmdb_id,
        "title" => "TMDB Movie",
        "overview" => "Overview",
        "poster_path" => "/p.jpg",
        "release_date" => "2020-01-01",
        "runtime" => 100,
        "popularity" => 2.5
      }

      allow_any_instance_of(TmdbService).to receive(:movie_details).with(tmdb_id.to_s).and_return(tmdb_data)

      expect {
        post "/watchlist_items", params: { movie_id: tmdb_id }
      }.to change { Movie.count }.by(1)

      user.reload
      expect(user.watchlist.watchlist_items.count).to eq(1)
      expect(response).to have_http_status(:redirect)
    end

    it "does not add when movie_id is blank" do
      user = create(:user)
      login_as(user, scope: :user)

      post "/watchlist_items", params: { movie_id: "" }
      expect(response).to have_http_status(:redirect)
    end

    it "does not allow unauthenticated users" do
      movie = create(:movie)
      post "/watchlist_items", params: { movie_id: movie.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /watchlist_items/:id (destroy)" do
    it "removes an existing watchlist item" do
      user = create(:user)
      login_as(user, scope: :user)
      movie = create(:movie)
      watchlist = user.create_watchlist
      item = watchlist.watchlist_items.create!(movie: movie)

      expect {
        delete "/watchlist_items/#{item.id}"
      }.to change { WatchlistItem.exists?(item.id) }.from(true).to(false)

      expect(response).to have_http_status(:redirect)
    end

    it "redirects with alert when item not found" do
      user = create(:user)
      login_as(user, scope: :user)

      delete "/watchlist_items/999999"
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /watchlist_items/restore (restore)" do
    it "restores a movie to the user's watchlist using tmdb id" do
      user = create(:user, username: "u#{SecureRandom.hex(6)}")
      login_as(user, scope: :user)

      tmdb_id = 8_888
      tmdb_data = {
        "id" => tmdb_id,
        "title" => "Restore Movie",
        "overview" => "Overview",
        "poster_path" => "/p.jpg",
        "release_date" => "2021-01-01",
        "runtime" => 95,
        "popularity" => 1.2
      }
      allow_any_instance_of(TmdbService).to receive(:movie_details).with(tmdb_id.to_s).and_return(tmdb_data)

      expect {
        post "/watchlist_items/restore", params: { movie_id: tmdb_id }
      }.to change { Movie.count }.by(1)

      user.reload
      expect(user.watchlist.watchlist_items.count).to eq(1)
      expect(response).to have_http_status(:redirect)
    end

    it "does nothing if movie_id blank" do
      user = create(:user)
      login_as(user, scope: :user)

      post "/watchlist_items/restore", params: { movie_id: "" }
      expect(response).to have_http_status(:redirect)
    end
  end
end
