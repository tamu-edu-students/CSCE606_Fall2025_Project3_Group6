class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_movie, only: [ :create, :edit, :update, :destroy ]
  before_action :set_review, only: [ :edit, :update, :destroy, :vote, :report ]
  before_action :authorize_user!, only: [ :edit, :update, :destroy ]

  def my_reviews
    @reviews = current_user.reviews.includes(:movie).by_date
  end

  def create
    @review = @movie.reviews.build(review_params)
    @review.user = current_user

    if @review.save
      redirect_to movie_path(@movie), notice: "Review was successfully created."
    else
      redirect_to movie_path(@movie), alert: @review.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to movie_path(@movie), notice: "Review was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to movie_path(@movie), notice: "Review was successfully deleted."
  end

  def vote
    value = params[:value].to_i
    existing_vote = @review.votes.find_by(user: current_user)

    if existing_vote
      if existing_vote.value == value
        existing_vote.destroy
      else
        existing_vote.update(value: value)
      end
    else
      @review.votes.create(user: current_user, value: value)
    end

    redirect_back(fallback_location: root_path)
  end

  def report
    if @review.reported?
      redirect_back(fallback_location: root_path, alert: "This review has already been reported.")
    else
      @review.update(reported: true)
      redirect_back(fallback_location: root_path, notice: "Review has been reported to moderators.")
    end
  end

  private

  def set_movie
    @movie = Movie.find_by!(tmdb_id: params[:movie_id])
  end

  def set_review
    @review = Review.find(params[:id])
  end

  def authorize_user!
    unless @review.user == current_user || current_user.admin?
      redirect_to root_path, alert: "You are not authorized to perform this action."
    end
  end

  def review_params
    params.require(:review).permit(:body, :rating)
  end
end
