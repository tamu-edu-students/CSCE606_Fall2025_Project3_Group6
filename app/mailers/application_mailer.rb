class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@cinematico.app"
  layout "mailer"

  # Required for Devise mailers like confirmation_url
  include Devise::Controllers::UrlHelpers

  # Ensures URL generation works in mailer context
  default_url_options[:host] = "cinematico.app"
end
