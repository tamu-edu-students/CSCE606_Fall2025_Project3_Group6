require 'rails_helper'

RSpec.describe Person, type: :model do
  describe "associations" do
    it { should have_many(:movie_people).dependent(:destroy) }
    it { should have_many(:movies).through(:movie_people) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe ".find_or_create_from_tmdb" do
    context "when person does not exist" do
      it "creates a new person" do
        expect {
          Person.find_or_create_from_tmdb(1, "Leonardo DiCaprio", "/profile.jpg")
        }.to change(Person, :count).by(1)
      end

      it "sets attributes correctly" do
        person = Person.find_or_create_from_tmdb(1, "Leonardo DiCaprio", "/profile.jpg")
        expect(person.tmdb_id).to eq(1)
        expect(person.name).to eq("Leonardo DiCaprio")
        expect(person.profile_path).to eq("/profile.jpg")
      end
    end

    context "when person already exists" do
      let!(:existing_person) { create(:person, tmdb_id: 1, name: "Old Name") }

      it "does not create a duplicate" do
        expect {
          Person.find_or_create_from_tmdb(1, "Leonardo DiCaprio")
        }.not_to change(Person, :count)
      end
    end
  end

  describe "#profile_url" do
    let(:person) { create(:person, profile_path: "/profile.jpg") }

    it "returns full profile URL" do
      expect(person.profile_url).to eq("https://image.tmdb.org/t/p/w500/profile.jpg")
    end

    context "without profile_path" do
      let(:person) { create(:person, profile_path: nil) }

      it "returns nil" do
        expect(person.profile_url).to be_nil
      end
    end
  end
end
