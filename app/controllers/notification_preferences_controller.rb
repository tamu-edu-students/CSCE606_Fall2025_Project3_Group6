class NotificationPreferencesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_preference_exists

  def edit
    @preference = current_user.notification_preference
  end

  def update
    @preference = current_user.notification_preference

    if @preference.update(preference_params)
      redirect_to edit_notification_preferences_path, notice: "Notification preferences updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def preference_params
    params.require(:notification_preference).permit(:review_created, :review_voted, :user_followed, :email_notifications)
  end

  def ensure_preference_exists
    current_user.create_notification_preference! unless current_user.notification_preference
  end
end
