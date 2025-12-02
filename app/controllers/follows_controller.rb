class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    current_user.followed_users << @user
    redirect_back(fallback_location: user_path(@user))
  end

  def destroy
    current_user.followed_users.delete(@user)
    redirect_back(fallback_location: user_path(@user))
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
