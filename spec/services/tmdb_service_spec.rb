require 'rails_helper'

RSpec.describe TmdbService do
  let(:service) { described_class.new }
  let(:api_key) { "test_api_key" }
  let(:base_url) { "https://api.themoviedb.org/3" }

  before do
    allow(ENV).to receive(:fetch).with("TMDB_API_KEY", "").and_return(api_key)
    Rails.cache.clear
  end

  describe "#search_movies" do
    let(:query) { "Inception" }
    let(:response_body) do
      {
        "results" => [
          {
            "id" => 27205,
            "title" => "Inception",
            "overview" => "A mind-bending thriller",
            "poster_path" => "/poster.jpg",
            "release_date" => "2010-07-16",
            "popularity" => 50.5,
            "vote_average" => 8.8
          }
        ],
        "total_pages" => 1,
        "total_results" => 1
      }
    end

    context "with valid query" do
      it "returns search results" do
        stub_request(:get, "#{base_url}/search/movie")
          .with(query: hash_including(api_key: api_key, query: query))
          .to_return(status: 200, body: response_body.to_json)

        result = service.search_movies(query)

        expect(result["results"]).to be_present
        expect(result["total_results"]).to eq(1)
      end

      it "caches search results" do
        stub_request(:get, "#{base_url}/search/movie")
          .to_return(status: 200, body: response_body.to_json)

        service.search_movies(query)
        cached = Rails.cache.read("tmdb_search_#{query.downcase}_page_1")

        expect(cached).to be_present
        expect(cached["total_results"]).to eq(1)
      end

      it "returns cached results on subsequent calls" do
        stub_request(:get, "#{base_url}/search/movie")
          .to_return(status: 200, body: response_body.to_json)

        service.search_movies(query)
        service.search_movies(query)

        expect(a_request(:get, "#{base_url}/search/movie")).to have_been_made.once
      end
    end

    context "with empty query" do
      it "returns empty results" do
        result = service.search_movies("")

        expect(result["results"]).to eq([])
        expect(result["total_pages"]).to eq(0)
        expect(result["total_results"]).to eq(0)
      end

      it "does not make API call" do
        service.search_movies("")

        expect(a_request(:get, /#{base_url}/)).not_to have_been_made
      end
    end

    context "when rate limited" do
      it "returns cached results if available" do
        # First, cache some results
        stub_request(:get, "#{base_url}/search/movie")
          .to_return(status: 200, body: response_body.to_json)

        service.search_movies(query)

        # Then simulate rate limit
        stub_request(:get, "#{base_url}/search/movie")
          .to_return(status: 429)

        result = service.search_movies(query)

        expect(result["results"]).to be_present
      end

      it "returns error message when no cache available" do
        stub_request(:get, "#{base_url}/search/movie")
          .to_return(status: 429)

        result = service.search_movies(query)

        expect(result["error"]).to include("Rate limit exceeded")
        expect(result["results"]).to eq([])
      end
    end

    context "when API fails" do
      it "returns error message" do
        stub_request(:get, "#{base_url}/search/movie")
          .to_return(status: 500)

        result = service.search_movies(query)

        expect(result["error"]).to be_present
        expect(result["results"]).to eq([])
      end
    end
  end

  describe "#movie_details" do
    let(:tmdb_id) { 27205 }
    let(:response_body) do
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
          "cast" => [ { "id" => 1, "name" => "Leonardo DiCaprio", "character" => "Cobb" } ],
          "crew" => [ { "id" => 2, "name" => "Christopher Nolan", "job" => "Director" } ]
        }
      }
    end

    context "with valid tmdb_id" do
      it "returns movie details" do
        stub_request(:get, "#{base_url}/movie/#{tmdb_id}")
          .with(query: hash_including(api_key: api_key, append_to_response: "credits,videos"))
          .to_return(status: 200, body: response_body.to_json)

        result = service.movie_details(tmdb_id)

        expect(result["id"]).to eq(tmdb_id)
        expect(result["title"]).to eq("Inception")
      end

      it "caches movie details" do
        stub_request(:get, "#{base_url}/movie/#{tmdb_id}")
          .with(query: hash_including(append_to_response: "credits,videos"))
          .to_return(status: 200, body: response_body.to_json)

        service.movie_details(tmdb_id)
        cached = Rails.cache.read("tmdb_movie_#{tmdb_id}")

        expect(cached).to be_present
        expect(cached["title"]).to eq("Inception")
      end
    end

    context "with blank tmdb_id" do
      it "returns nil" do
        result = service.movie_details("")

        expect(result).to be_nil
      end
    end

    context "when movie not found" do
      it "returns nil" do
        stub_request(:get, "#{base_url}/movie/#{tmdb_id}")
          .to_return(status: 404)

        result = service.movie_details(tmdb_id)

        expect(result).to be_nil
      end
    end
  end

  describe "#similar_movies" do
    let(:tmdb_id) { 27205 }
    let(:response_body) do
      {
        "results" => [
          { "id" => 1, "title" => "Interstellar" },
          { "id" => 2, "title" => "The Matrix" }
        ],
        "total_pages" => 1
      }
    end

    context "with valid tmdb_id" do
      it "returns similar movies" do
        stub_request(:get, "#{base_url}/movie/#{tmdb_id}/similar")
          .to_return(status: 200, body: response_body.to_json)

        result = service.similar_movies(tmdb_id)

        expect(result["results"]).to be_present
        expect(result["results"].length).to eq(2)
      end

      it "caches similar movies" do
        stub_request(:get, "#{base_url}/movie/#{tmdb_id}/similar")
          .to_return(status: 200, body: response_body.to_json)

        service.similar_movies(tmdb_id)
        cached = Rails.cache.read("tmdb_similar_#{tmdb_id}_page_1")

        expect(cached).to be_present
      end
    end

    context "when API fails" do
      it "returns error message" do
        stub_request(:get, "#{base_url}/movie/#{tmdb_id}/similar")
          .to_return(status: 500)

        result = service.similar_movies(tmdb_id)

        expect(result["error"]).to be_present
        expect(result["results"]).to eq([])
      end
    end
  end

  describe "#genres" do
    let(:response_body) do
      {
        "genres" => [
          { "id" => 28, "name" => "Action" },
          { "id" => 35, "name" => "Comedy" }
        ]
      }
    end

    it "returns genres list" do
      stub_request(:get, "#{base_url}/genre/movie/list")
        .to_return(status: 200, body: response_body.to_json)

      result = service.genres

      expect(result["genres"]).to be_present
      expect(result["genres"].length).to eq(2)
    end

    it "caches genres" do
      stub_request(:get, "#{base_url}/genre/movie/list")
        .to_return(status: 200, body: response_body.to_json)

      service.genres
      cached = Rails.cache.read("tmdb_genres")

      expect(cached).to be_present
    end
  end

  describe ".poster_url" do
    it "returns full poster URL" do
      url = described_class.poster_url("/poster.jpg")
      expect(url).to eq("https://image.tmdb.org/t/p/w500/poster.jpg")
    end

    it "returns nil for blank poster_path" do
      url = described_class.poster_url("")
      expect(url).to be_nil
    end
  end
end
