class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:public_profile]

  def show
    @user = current_user
    @stats = @user.user_stat if @user.respond_to?(:user_stat)
  end

  def public_profile
    @user = User.find_by!(username: params[:username])

    # Respect privacy setting
    if @user.profile_public == false
      redirect_to root_path, alert: "This profile is private."
      return
    end

    @stats = @user.user_stat if @user.respond_to?(:user_stat)
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
