require 'rails_helper'

RSpec.describe StatsService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:watch_history) { create(:watch_history, user: user) }
  let(:service) { described_class.new(user) }

  describe "#calculate_overview" do
    context "with watch history data" do
      let!(:movie1) { create(:movie, title: "Inception", runtime: 148) }
      let!(:movie2) { create(:movie, title: "The Matrix", runtime: 136) }
      let!(:action) { create(:genre, name: "Action", tmdb_id: 101) }
      let!(:drama) { create(:genre, name: "Drama", tmdb_id: 102) }

      before do
        movie1.genres << action
        movie2.genres << drama
        create(:watch_log, watch_history: watch_history, movie: movie1, watched_on: Date.new(2024, 1, 1))
        create(:watch_log, watch_history: watch_history, movie: movie2, watched_on: Date.new(2024, 1, 2))
        create(:review, user: user, movie: movie1, body: "This review text is long enough", rating: 8)
        create(:log, user: user, movie: movie2, watched_on: Date.new(2024, 1, 2), rewatch: true)
      end

      it "returns aggregated overview numbers and genre breakdown" do
        overview = service.calculate_overview

        expect(overview[:total_movies]).to eq(2)
        expect(overview[:total_hours]).to eq(284) # minutes
        expect(overview[:total_reviews]).to eq(1)
        expect(overview[:total_rewatches]).to eq(1)
        expect(overview[:genre_breakdown]).to eq({ "Action" => 1, "Drama" => 1 })
      end
    end

    context "when the same movie is watched multiple times" do
      before do
        movie = create(:movie, runtime: 100)
        create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 1, 1))
        create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 2, 1))
      end

      it "counts rewatches based on duplicate watch logs" do
        overview = service.calculate_overview
        expect(overview[:total_rewatches]).to eq(1)
      end
    end

    context "with no watch logs" do
      it "returns zeroed stats" do
        expect(service.calculate_overview).to eq(
          total_movies: 0,
          total_hours: 0,
          total_reviews: 0,
          total_rewatches: 0,
          genre_breakdown: {},
          decade_breakdown: {}
        )
      end
    end

    context "when an error occurs" do
      before do
        allow(service).to receive(:user_watch_logs).and_raise(StandardError.new("boom"))
      end

      it "fails safely with zeroed stats" do
        overview = service.calculate_overview
        expect(overview.values_at(:total_movies, :total_hours, :total_reviews, :total_rewatches)).to all(eq(0))
        expect(overview[:genre_breakdown]).to eq({})
      end
    end
  end

  describe "#most_watched_movies" do
    let!(:movie1) { create(:movie, title: "Alpha") }
    let!(:movie2) { create(:movie, title: "Beta") }

    before do
      create(:watch_log, watch_history: watch_history, movie: movie1, watched_on: Date.new(2024, 1, 1))
      create(:watch_log, watch_history: watch_history, movie: movie1, watched_on: Date.new(2024, 2, 1))
      create(:watch_log, watch_history: watch_history, movie: movie2, watched_on: Date.new(2024, 1, 5))
    end

    it "orders by rewatch count descending, then total watches" do
      top = service.most_watched_movies(limit: 2)
      expect(top.first[:movie]).to eq(movie1)
      expect(top.first[:rewatch_count]).to eq(1)
      expect(top.first[:watch_count]).to eq(2)
    end

    it "falls back safely when nothing is watched" do
      allow(service).to receive(:user_watch_logs).and_return(WatchLog.none)
      expect(service.most_watched_movies).to eq([])
    end
  end

  describe "#calculate_top_contributors" do
    let!(:movie1) { create(:movie, title: "Inception") }
    let!(:movie2) { create(:movie, title: "The Matrix") }
    let!(:genre1) { create(:genre, name: "Action") }
    let!(:genre2) { create(:genre, name: "Sci-Fi", tmdb_id: 878) }
    let!(:director) { create(:person, name: "Christopher Nolan", tmdb_id: 2) }
    let!(:actor) { create(:person, name: "Leonardo DiCaprio", tmdb_id: 3) }

    before do
      movie1.genres << [ genre1, genre2 ]
      movie2.genres << genre1

      create(:movie_person, movie: movie1, person: director, role: "director")
      create(:movie_person, movie: movie1, person: actor, role: "cast")
      create(:movie_person, movie: movie2, person: director, role: "director")

      create(:watch_log, watch_history: watch_history, movie: movie1, watched_on: Date.new(2024, 1, 1))
      create(:watch_log, watch_history: watch_history, movie: movie2, watched_on: Date.new(2024, 1, 2))
    end

    it "returns top genres, directors, and actors ordered by count" do
      contributors = service.calculate_top_contributors

      expect(contributors[:top_genres].first).to eq({ name: "Action", count: 2 })
      expect(contributors[:top_directors].first).to include(name: "Christopher Nolan", count: 2)
      expect(contributors[:top_actors].first).to include(name: "Leonardo DiCaprio", count: 1)

      expect(contributors[:top_genres].length).to be <= 10
      expect(contributors[:top_directors].length).to be <= 10
      expect(contributors[:top_actors].length).to be <= 10
    end
  end

  describe "#calculate_trend_data" do
    let!(:movie) { create(:movie, title: "Test Movie") }

    before { travel_to Date.new(2024, 6, 15) }
    after { travel_back }

    context "with dated watch logs and ratings" do
      before do
        create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 3, 10), incoming_rating: 4)
        create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 3, 20), incoming_rating: 2)
        create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 4, 5), incoming_rating: 5)
      end

      it "builds a month-by-month activity trend including zero months" do
        trend_data = service.calculate_trend_data

        expect(trend_data[:activity_trend].first[:month]).to eq("2024-01")
        expect(trend_data[:activity_trend].last[:month]).to eq("2024-06")
        expect(trend_data[:activity_trend].find { |row| row[:month] == "2024-03" }[:count]).to eq(2)
        expect(trend_data[:activity_trend].find { |row| row[:month] == "2024-04" }[:count]).to eq(1)
      end

      it "averages ratings per month using synced legacy logs" do
        trend_data = service.calculate_trend_data

        march = trend_data[:rating_trend].find { |row| row[:month] == "2024-03" }
        april = trend_data[:rating_trend].find { |row| row[:month] == "2024-04" }

        expect(march[:average_rating]).to eq(3.0) # (4 + 2) / 2
        expect(april[:average_rating]).to eq(5.0)
      end
    end

    context "with no watch logs" do
      it "returns zeroed activity trend and empty rating trend" do
        trend_data = service.calculate_trend_data

        expect(trend_data[:activity_trend]).not_to be_empty
        expect(trend_data[:activity_trend].all? { |row| row[:count] == 0 }).to be(true)
        expect(trend_data[:rating_trend]).to eq([])
      end
    end
  end

  describe "#calculate_heatmap_data" do
    let!(:movie) { create(:movie, title: "Test Movie") }

    before { travel_to Date.new(2024, 6, 15) }
    after { travel_back }

    it "counts watches for the requested year and fills missing days" do
      create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 1, 1))
      create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 3, 5))

      heatmap = service.calculate_heatmap_data(year: 2024)

      expect(heatmap["2024-01-01"]).to eq(1)
      expect(heatmap["2024-03-05"]).to eq(1)
      expect(heatmap["2024-06-15"]).to eq(0)
      expect(heatmap.keys.min).to eq("2024-01-01")
      expect(heatmap.keys.max).to eq("2024-06-15")
    end

    it "ignores logs outside the selected year" do
      create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2023, 12, 31))
      create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.new(2024, 1, 2))

      heatmap = service.calculate_heatmap_data(year: 2023)

      expect(heatmap["2023-12-31"]).to eq(1)
      expect(heatmap).not_to have_key("2024-01-02")
      expect(heatmap.keys.min).to eq("2023-01-01")
      expect(heatmap.keys.max).to eq("2023-12-31")
    end

    it "returns zero counts when no logs exist" do
      heatmap = service.calculate_heatmap_data(year: 2024)

      expect(heatmap.values.uniq).to eq([ 0 ])
      expect(heatmap.keys.min).to eq("2024-01-01")
      expect(heatmap.keys.max).to eq("2024-06-15")
    end
  end

  describe "#heatmap_years" do
    before { travel_to Date.new(2024, 6, 15) }
    after { travel_back }

    it "returns distinct years with watch logs in descending order" do
      create(:watch_log, watch_history: watch_history, movie: create(:movie), watched_on: Date.new(2022, 5, 1))
      create(:watch_log, watch_history: watch_history, movie: create(:movie), watched_on: Date.new(2024, 1, 1))
      create(:watch_log, watch_history: watch_history, movie: create(:movie), watched_on: Date.new(2023, 7, 1))

      expect(service.heatmap_years).to eq([ 2024, 2023, 2022 ])
    end

    it "defaults to the current year when no data exists" do
      expect(service.heatmap_years).to eq([ 2024, 2023, 2022, 2021, 2020 ])
    end
  end
end
