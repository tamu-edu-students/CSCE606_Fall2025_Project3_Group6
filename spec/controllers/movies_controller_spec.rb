require 'rails_helper'

RSpec.describe MoviesController, type: :controller do
  let(:tmdb_service) { instance_double(TmdbService) }

  before do
    allow(TmdbService).to receive(:new).and_return(tmdb_service)
  end

  describe "GET #index" do
    context "with empty query" do
      before do
        allow(tmdb_service).to receive(:genres).and_return({ "genres" => [] })
      end

      it "renders index template" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "shows empty state message" do
        get :index
        expect(assigns(:movies)).to eq([])
        expect(assigns(:query)).to be_blank
      end
    end

    context "with valid query" do
      let(:search_results) do
        {
          "results" => [
            {
              "id" => 27205,
              "title" => "Inception",
              "overview" => "A mind-bending thriller",
              "poster_path" => "/poster.jpg",
              "release_date" => "2010-07-16",
              "popularity" => 50.5,
              "vote_average" => 8.8,
              "genre_ids" => [ 28, 878 ]
            }
          ],
          "total_pages" => 1,
          "total_results" => 1
        }
      end

      let(:genres_data) do
        {
          "genres" => [
            { "id" => 28, "name" => "Action" },
            { "id" => 878, "name" => "Science Fiction" }
          ]
        }
      end

      before do
        allow(tmdb_service).to receive(:search_movies).and_return(search_results)
        allow(tmdb_service).to receive(:genres).and_return(genres_data)
      end

      it "returns search results" do
        get :index, params: { query: "Inception" }
        expect(assigns(:movies)).to be_present
        expect(assigns(:total_results)).to eq(1)
      end

      it "loads genres for filter" do
        get :index, params: { query: "Inception" }
        expect(assigns(:genres)).to be_present
      end

      context "with genre filter" do
        let!(:genre) { create(:genre, tmdb_id: 28, name: "Action") }

        it "filters results by genre" do
          get :index, params: { query: "Inception", genre: 28 }
          movies = assigns(:movies)
          expect(movies.all? { |m| (m["genre_ids"] || []).include?(28) }).to be true
        end
      end

      context "with decade filter" do
        it "filters results by decade" do
          get :index, params: { query: "Inception", decade: 2010 }
          movies = assigns(:movies)
          expect(movies.all? do |m|
            next false unless m["release_date"]
            begin
              year = Date.parse(m["release_date"]).year
            rescue ArgumentError, TypeError
              next false
            end
            year && (year / 10) * 10 == 2010
          end).to be true
        end
      end

      context "with sorting" do
        it "sorts by popularity" do
          get :index, params: { query: "Inception", sort_by: "popularity" }
          movies = assigns(:movies)
          expect(movies).to eq(movies.sort_by { |m| -(m["popularity"] || 0) })
        end

        it "sorts by rating" do
          get :index, params: { query: "Inception", sort_by: "rating" }
          movies = assigns(:movies)
          expect(movies).to eq(movies.sort_by { |m| -(m["vote_average"] || 0) })
        end

        it "sorts by release date" do
          get :index, params: { query: "Inception", sort_by: "release_date" }
          movies = assigns(:movies)
          sorted = movies.sort_by do |m|
            release_date = m["release_date"]
            release_date ? Date.parse(release_date) : Date.new(1900, 1, 1)
          end.reverse
          expect(movies).to eq(sorted)
        end
      end

      context "when API returns error" do
        before do
          allow(tmdb_service).to receive(:search_movies).and_return({
            "error" => "Rate limit exceeded",
            "results" => [],
            "total_pages" => 0,
            "total_results" => 0
          })
        end

        it "displays error message" do
          get :index, params: { query: "Inception" }
          expect(assigns(:error)).to be_present
          expect(assigns(:movies)).to eq([])
        end
      end
    end
  end

  describe "GET #show" do
    let(:tmdb_id) { 27205 }
    let(:movie_data) do
      {
        "id" => tmdb_id,
        "title" => "Inception",
        "overview" => "A mind-bending thriller",
        "poster_path" => "/poster.jpg",
        "release_date" => "2010-07-16",
        "runtime" => 148,
        "popularity" => 50.5,
        "genres" => [ { "id" => 28, "name" => "Action" } ],
        "credits" => {
          "cast" => [
            { "id" => 1, "name" => "Leonardo DiCaprio", "character" => "Cobb", "profile_path" => "/profile.jpg" }
          ],
          "crew" => [
            { "id" => 2, "name" => "Christopher Nolan", "job" => "Director", "profile_path" => "/director.jpg" }
          ]
        }
      }
    end

    let(:similar_movies_data) do
      {
        "results" => [
          { "id" => 1, "title" => "Interstellar", "poster_path" => "/interstellar.jpg" },
          { "id" => 2, "title" => "The Matrix", "poster_path" => "/matrix.jpg" }
        ]
      }
    end

    context "with cached movie" do
      let!(:movie) { create(:movie, tmdb_id: tmdb_id, cached_at: 1.hour.ago) }

      before do
        allow(tmdb_service).to receive(:similar_movies).and_return({ "results" => [] })
      end

      it "loads movie from database" do
        get :show, params: { id: tmdb_id }
        expect(assigns(:movie)).to eq(movie)
      end

      it "does not call TMDb API" do
        expect(tmdb_service).not_to receive(:movie_details)
        get :show, params: { id: tmdb_id }
      end
    end

    context "without cached movie" do
      before do
        allow(tmdb_service).to receive(:movie_details).and_return(movie_data)
        allow(tmdb_service).to receive(:similar_movies).and_return(similar_movies_data)
      end

      it "fetches movie from TMDb API" do
        get :show, params: { id: tmdb_id }
        expect(assigns(:movie)).to be_present
        expect(assigns(:movie).title).to eq("Inception")
      end

      it "loads similar movies" do
        get :show, params: { id: tmdb_id }
        expect(assigns(:similar_movies)).to be_present
        expect(assigns(:similar_movies).length).to eq(2)
      end
    end

    context "when movie not found" do
      before do
        allow(tmdb_service).to receive(:movie_details).and_return(nil)
      end

      it "shows error message" do
        get :show, params: { id: 999999 }
        expect(assigns(:error)).to be_present
        expect(assigns(:movie)).to be_nil
      end
    end

    context "when similar movies API fails" do
      let!(:movie) { create(:movie, tmdb_id: tmdb_id) }

      before do
        allow(tmdb_service).to receive(:similar_movies).and_return({
          "error" => "API request failed",
          "results" => []
        })
      end
    end
  end

  describe "GET #search" do
    context "with empty query" do
      it "returns error message" do
        get :search, params: { query: "" }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Please enter")
      end
    end

    context "with valid query" do
      let(:search_results) do
        {
          "results" => [ { "id" => 1, "title" => "Test Movie" } ],
          "total_pages" => 1,
          "total_results" => 1
        }
      end

      before do
        allow(tmdb_service).to receive(:search_movies).and_return(search_results)
      end

      it "returns JSON results" do
        get :search, params: { query: "Test" }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["results"]).to be_present
      end
    end
  end
end
