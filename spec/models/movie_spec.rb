require 'rails_helper'

RSpec.describe Movie, type: :model do
  describe "associations" do
    it { should have_many(:movie_genres).dependent(:destroy) }
    it { should have_many(:genres).through(:movie_genres) }
    it { should have_many(:movie_people).dependent(:destroy) }
    it { should have_many(:people).through(:movie_people) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:tmdb_id) }
    it { should validate_uniqueness_of(:tmdb_id) }
  end

  describe ".find_or_create_from_tmdb" do
    let(:tmdb_data) do
      {
        "id" => 27205,
        "title" => "Inception",
        "overview" => "A mind-bending thriller",
        "poster_path" => "/poster.jpg",
        "release_date" => "2010-07-16",
        "runtime" => 148,
        "popularity" => 50.5
      }
    end

    context "when movie does not exist" do
      it "creates a new movie" do
        expect {
          Movie.find_or_create_from_tmdb(tmdb_data)
        }.to change(Movie, :count).by(1)
      end

      it "sets all attributes correctly" do
        movie = Movie.find_or_create_from_tmdb(tmdb_data)
        expect(movie.tmdb_id).to eq(27205)
        expect(movie.title).to eq("Inception")
        expect(movie.overview).to eq("A mind-bending thriller")
        expect(movie.poster_path).to eq("/poster.jpg")
        expect(movie.release_date).to eq(Date.parse("2010-07-16"))
        expect(movie.runtime).to eq(148)
        expect(movie.popularity).to eq(50.5)
      end

      it "sets cached_at timestamp" do
        movie = Movie.find_or_create_from_tmdb(tmdb_data)
        expect(movie.cached_at).to be_present
      end
    end

    context "when movie already exists" do
      let!(:existing_movie) { create(:movie, tmdb_id: 27205, title: "Old Title") }

      it "does not create a duplicate" do
        expect {
          Movie.find_or_create_from_tmdb(tmdb_data)
        }.not_to change(Movie, :count)
      end

      it "updates the existing movie" do
        movie = Movie.find_or_create_from_tmdb(tmdb_data)
        expect(movie.title).to eq("Inception")
        expect(movie.id).to eq(existing_movie.id)
      end
    end

    context "with blank tmdb_data" do
      it "returns nil" do
        expect(Movie.find_or_create_from_tmdb(nil)).to be_nil
      end
    end
  end

  describe "#poster_url" do
    let(:movie) { create(:movie, poster_path: "/poster.jpg") }

    it "returns full poster URL" do
      expect(movie.poster_url).to eq("https://image.tmdb.org/t/p/w500/poster.jpg")
    end

    context "without poster_path" do
      let(:movie) { create(:movie, poster_path: nil) }

      it "returns nil" do
        expect(movie.poster_url).to be_nil
      end
    end
  end

  describe "#release_year" do
    it "returns the year from release_date" do
      movie = create(:movie, release_date: Date.parse("2010-07-16"))
      expect(movie.release_year).to eq(2010)
    end

    context "without release_date" do
      let(:movie) { create(:movie, release_date: nil) }

      it "returns nil" do
        expect(movie.release_year).to be_nil
      end
    end
  end

  describe "#decade" do
    it "returns the decade" do
      movie = create(:movie, release_date: Date.parse("2010-07-16"))
      expect(movie.decade).to eq(2010)
    end

    it "returns correct decade for 1999" do
      movie = create(:movie, release_date: Date.parse("1999-12-31"))
      expect(movie.decade).to eq(1990)
    end
  end

  describe "#cached?" do
    context "with recent cache" do
      let(:movie) { create(:movie, cached_at: 1.hour.ago) }

      it "returns true" do
        expect(movie.cached?).to be true
      end
    end

    context "with expired cache" do
      let(:movie) { create(:movie, cached_at: 25.hours.ago) }

      it "returns false" do
        expect(movie.cached?).to be false
      end
    end

    context "without cache" do
      let(:movie) { create(:movie, cached_at: nil) }

      it "returns false" do
        expect(movie.cached?).to be false
      end
    end
  end

  describe "scopes" do
    describe ".cached" do
      it "returns movies with cached_at" do
        cached_movie = create(:movie, cached_at: Time.current)
        uncached_movie = create(:movie, cached_at: nil)

        expect(Movie.cached).to include(cached_movie)
        expect(Movie.cached).not_to include(uncached_movie)
      end
    end

    describe ".recently_cached" do
      it "returns movies cached within 24 hours" do
        recent = create(:movie, cached_at: 1.hour.ago)
        old = create(:movie, cached_at: 25.hours.ago)

        expect(Movie.recently_cached).to include(recent)
        expect(Movie.recently_cached).not_to include(old)
      end
    end
  end
end
