class NotificationMailer < ApplicationMailer
  # Generic reusable notification mailer
  #
  # Usage:
  #   NotificationMailer.send_notification(user, "You got a new upvote!").deliver_later
  #
  def send_notification(user, message, url: nil)
    @user = user
    @message = message
    @url = url # optional link for CTA button

    mail(to: @user.email, subject: "One Notification from Cinematico")
  end
end
