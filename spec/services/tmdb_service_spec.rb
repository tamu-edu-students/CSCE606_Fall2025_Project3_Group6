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

    context "with empty query" do
      it "does not make API call" do
        service.search_movies("")

        expect(a_request(:get, /#{base_url}/)).not_to have_been_made
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

    context "with blank tmdb_id" do
      it "returns nil" do
        result = service.movie_details("")

        expect(result).to be_nil
      end
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
