class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    current_user.followed_users << @user

    # Notify the user who was followed
    NotificationCreator.call(
      actor: current_user,
      recipient: @user,
      notification_type: "user.followed",
      body: "#{current_user.username} started following you"
    )

    redirect_back(fallback_location: user_path(@user))
  end

  def destroy
    NotificationCreator.call(
      actor: current_user,
      recipient: @user,
      notification_type: "user.followed",
      body: "#{current_user.username} stopped following you"
    )
    current_user.followed_users.delete(@user)
    redirect_back(fallback_location: user_path(@user))
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
