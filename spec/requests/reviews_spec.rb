require 'rails_helper'

RSpec.describe "Reviews", type: :request do
  include Warden::Test::Helpers

  before do
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  before(:each) do
    allow_any_instance_of(User).to receive(:admin?).and_return(false)
    begin
      User.send(:public, :admin?)
    rescue StandardError
      # ignore if method visibility cannot be changed
    end
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:movie) { create(:movie, tmdb_id: 999) }

  describe "POST /movies/:movie_id/reviews (create)" do
    it "creates a review with valid params" do
      login_as(user, scope: :user)
      expect {
        post movie_reviews_path(movie), params: { review: { body: "This is a good movie.", rating: 8 } }
      }.to change(Review, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "redirects with error on invalid params" do
      login_as(user, scope: :user)
      expect {
        post movie_reviews_path(movie), params: { review: { body: "short", rating: 11 } }
      }.not_to change(Review, :count)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /movies/:movie_id/reviews/:id/edit and PATCH update" do
    it "allows owner to edit and update successfully" do
      login_as(user, scope: :user)
      review = create(:review, user: user, movie: movie, body: "A valid review body.", rating: 7)

      get edit_movie_review_path(movie, review)
      expect(response).to have_http_status(:success)

      patch movie_review_path(movie, review), params: { review: { body: "Updated body content.", rating: 9 } }
      expect(response).to have_http_status(:redirect)
      expect(review.reload.body).to eq("Updated body content.")
    end

    it "renders edit with errors on invalid update" do
      login_as(user, scope: :user)
      review = create(:review, user: user, movie: movie, body: "A valid review body.", rating: 7)

      patch movie_review_path(movie, review), params: { review: { body: "short", rating: 0 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "prevents non-owner from editing" do
      login_as(other_user, scope: :user)
      review = create(:review, user: user, movie: movie, body: "A valid review body.", rating: 7)

      get edit_movie_review_path(movie, review)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /movies/:movie_id/reviews/:id" do
    it "deletes review for owner" do
      login_as(user, scope: :user)
      review = create(:review, user: user, movie: movie, body: "A valid review body.", rating: 7)

      expect {
        delete movie_review_path(movie, review)
      }.to change(Review, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /reviews/:id/vote" do
    it "creates a vote when none exists" do
      login_as(user, scope: :user)
      review = create(:review, user: other_user, movie: movie, body: "A good movie.", rating: 6)

      expect {
        post vote_review_path(review), params: { value: 1 }
      }.to change(Vote, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "destroys vote if same value posted" do
      login_as(user, scope: :user)
      review = create(:review, user: other_user, movie: movie, body: "A good movie.", rating: 6)
      create(:vote, review: review, user: user, value: 1)

      expect {
        post vote_review_path(review), params: { value: 1 }
      }.to change(Vote, :count).by(-1)
    end

    it "updates vote if different value posted" do
      login_as(user, scope: :user)
      review = create(:review, user: other_user, movie: movie, body: "A good movie.", rating: 6)
      v = create(:vote, review: review, user: user, value: 1)

      post vote_review_path(review), params: { value: -1 }
      expect(v.reload.value).to eq(-1)
    end
  end

  describe "POST /reviews/:id/report" do
    it "marks review as reported if not already" do
      login_as(user, scope: :user)
      review = create(:review, user: other_user, movie: movie, body: "A good movie.", rating: 6, reported: false)

      post report_review_path(review)
      expect(response).to have_http_status(:redirect)
      expect(review.reload.reported).to be true
    end

    it "redirects with alert if already reported" do
      login_as(user, scope: :user)
      review = create(:review, user: other_user, movie: movie, body: "A good movie.", rating: 6, reported: true)

      post report_review_path(review)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /my_reviews" do
    it "shows current user's reviews" do
      login_as(user, scope: :user)
      create(:review, user: user, movie: movie, body: "A valid review body.", rating: 5)

      get my_reviews_path
      expect(response).to have_http_status(:success)
      expect(assigns(:reviews).first.user).to eq(user)
    end
  end
end
