class UsersController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :public_profile ]

  def show
    if params[:id]
      @user = User.find(params[:id])
    elsif user_signed_in?
      @user = current_user
    else
      redirect_to new_user_session_path, alert: "Please sign in to view your profile."
      return
    end

    if @user != current_user && @user.profile_public == false
      redirect_to root_path, alert: "This profile is private."
      return
    end

    @stats = @user.user_stat if @user.respond_to?(:user_stat)
    @recent_reviews = @user.reviews.includes(:movie).by_date.limit(5)

    if current_user == @user
      @lists = @user.lists
    else
      @lists = @user.lists.where(public: true)
    end
  end

  def public_profile
    @user = User.find_by!(username: params[:username])

    # Respect privacy setting
    if @user.profile_public == false
      redirect_to root_path, alert: "This profile is private."
      return
    end

    @stats = @user.user_stat if @user.respond_to?(:user_stat)
    @recent_reviews = @user.reviews.includes(:movie).by_date.limit(5)

    if current_user == @user
      @lists = @user.lists
    else
      @lists = @user.lists.where(public: true)
    end

    render :show
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :profile_public)
  end
end
