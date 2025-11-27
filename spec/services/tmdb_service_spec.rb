require 'rails_helper'

RSpec.describe TmdbService, type: :service do
  let(:token) { "test-token" }

  before do
    @orig = ENV['TMDB_ACCESS_TOKEN']
    ENV['TMDB_ACCESS_TOKEN'] = token
    Rails.cache.clear
  end

  after do
    ENV['TMDB_ACCESS_TOKEN'] = @orig
    Rails.cache.clear
  end

  describe '.poster_url' do
    it 'returns full url for poster path' do
      expect(TmdbService.poster_url('/abc.jpg')).to include('image.tmdb.org')
    end

    it 'returns nil for blank poster_path' do
      expect(TmdbService.poster_url(nil)).to be_nil
    end
  end

  describe '#search_movies' do
    it 'returns empty results for blank query' do
      svc = TmdbService.new
      expect(svc.search_movies('')).to eq({ results: [], total_pages: 0, total_results: 0 })
    end

    it 'parses successful API response' do
      body = { "results" => [ { "id" => 1, "title" => "Foo" } ], "total_pages" => 1, "total_results" => 1 }
      stub_request(:get, "https://api.themoviedb.org/3/search/movie").with(query: hash_including({ "query"=>"Foo", "page"=>"1" })).to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

      svc = TmdbService.new
      res = svc.search_movies('Foo', page: 1)
      expect(res['results'].first['title']).to eq('Foo')
    end

    it 'handles rate limit 429' do
      stub_request(:get, "https://api.themoviedb.org/3/search/movie").with(query: hash_including({ "query"=>"X", "page"=>"1" })).to_return(status: 429, body: "")
      svc = TmdbService.new
      res = svc.search_movies('X', page: 1)
      expect(res[:error] || res['error']).to be_present
    end
  end

  describe '#movie_details' do
    it 'returns nil for blank id' do
      svc = TmdbService.new
      expect(svc.movie_details(nil)).to be_nil
    end

    it 'fetches and returns movie details' do
      tmdb_id = 123
      body = { "id" => tmdb_id, "title" => "Movie 123" }
      stub_request(:get, "https://api.themoviedb.org/3/movie/#{tmdb_id}").with(query: hash_including({ "append_to_response"=>"credits,videos" })).to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

      svc = TmdbService.new
      res = svc.movie_details(tmdb_id)
      expect(res['title']).to eq('Movie 123')
    end
  end

  describe '#similar_movies' do
    it 'returns empty for blank id' do
      svc = TmdbService.new
      expect(svc.similar_movies(nil)).to eq({ results: [], total_pages: 0 })
    end

    it 'fetches similar movies' do
      tmdb_id = 1
      body = { "results" => [ { "id" => 2, "title" => "Bar" } ], "total_pages" => 1 }
      stub_request(:get, "https://api.themoviedb.org/3/movie/#{tmdb_id}/similar").with(query: hash_including({ "page"=>"1" })).to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

      svc = TmdbService.new
      res = svc.similar_movies(tmdb_id, page: 1)
      expect(res['results'].first['title']).to eq('Bar')
    end
  end

  describe '#genres' do
    it 'fetches genres list' do
      body = { "genres" => [ { "id" => 1, "name" => "Action" } ] }
      stub_request(:get, "https://api.themoviedb.org/3/genre/movie/list").to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

      svc = TmdbService.new
      res = svc.genres
      expect(res['genres'].first['name']).to eq('Action')
    end
  end
end
require 'rails_helper'

RSpec.describe TmdbService do
  let(:service) { described_class.new }
  let(:access_token) { "test_access_token" }
  let(:base_url) { "https://api.themoviedb.org/3" }

  before do
    allow(ENV).to receive(:fetch).with("TMDB_ACCESS_TOKEN", "").and_return(access_token)
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
