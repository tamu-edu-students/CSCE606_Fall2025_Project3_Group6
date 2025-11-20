require 'rails_helper'

RSpec.describe Genre, type: :model do
  describe "associations" do
    it { should have_many(:movie_genres).dependent(:destroy) }
    it { should have_many(:movies).through(:movie_genres) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe ".find_or_create_from_tmdb" do
    context "when genre does not exist" do
      it "creates a new genre" do
        expect {
          Genre.find_or_create_from_tmdb(28, "Action")
        }.to change(Genre, :count).by(1)
      end

      it "sets attributes correctly" do
        genre = Genre.find_or_create_from_tmdb(28, "Action")
        expect(genre.tmdb_id).to eq(28)
        expect(genre.name).to eq("Action")
      end
    end

    context "when genre already exists" do
      let!(:existing_genre) { create(:genre, tmdb_id: 28, name: "Old Name") }

      it "does not create a duplicate" do
        expect {
          Genre.find_or_create_from_tmdb(28, "Action")
        }.not_to change(Genre, :count)
      end

      it "returns existing genre" do
        genre = Genre.find_or_create_from_tmdb(28, "Action")
        expect(genre.id).to eq(existing_genre.id)
      end
    end
  end
end
