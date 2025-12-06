class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :mark_read ]

  def index
    @notifications = current_user.notifications.recent

    respond_to do |format|
      format.html
      format.json { render json: @notifications.limit(50).map(&:as_json) }
    end
  end

  def mark_read
    @notification&.mark_as_read!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "notifications-dropdown",
            partial: "shared/notifications_dropdown",
            locals: { user: current_user, signed_in: true }
          ),
          turbo_stream.replace(
            "notifications-list",
            partial: "notifications/list",
            locals: { notifications: current_user.notifications.recent }
          )
        ]
      end
      format.html { head :no_content }
      format.json { head :no_content }
    end
  end

  def mark_all_read
    relation = current_user.notifications

    if Notification.column_names.include?("read_at")
      relation.unread.update_all(read_at: Time.current)
    elsif Notification.column_names.include?("read")
      relation.unread.update_all(read: true)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "notifications-dropdown",
            partial: "shared/notifications_dropdown",
            locals: { user: current_user, signed_in: true }
          ),
          turbo_stream.replace(
            "notifications-list",
            partial: "notifications/list",
            locals: { notifications: current_user.notifications.recent }
          )
        ]
      end
      format.html { head :no_content }
      format.json { head :no_content }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find_by(id: params[:id])
  end
end
