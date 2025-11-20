require 'rails_helper'

RSpec.describe "Movies", type: :request do
  let(:tmdb_service) { instance_double(TmdbService) }

  before do
    allow(TmdbService).to receive(:new).and_return(tmdb_service)
  end

  describe "GET /movies" do
    context "with empty query" do
      it "returns http success" do
        allow(tmdb_service).to receive(:genres).and_return({ "genres" => [] })
        get movies_path
        expect(response).to have_http_status(:success)
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
        get movies_path, params: { query: "Inception" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Inception")
      end
    end
  end

  describe "GET /movies/:id" do
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
          { "id" => 1, "title" => "Interstellar", "poster_path" => "/interstellar.jpg" }
        ]
      }
    end

    before do
      allow(tmdb_service).to receive(:movie_details).and_return(movie_data)
      allow(tmdb_service).to receive(:similar_movies).and_return(similar_movies_data)
    end

    it "returns movie details" do
      get movie_path(tmdb_id)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Inception")
    end
  end
end
