class Users::RegistrationsController < Devise::RegistrationsController
  layout "application"

  before_action :configure_permitted_parameters

  # Restore Devise behavior including flashes
  def create
    super
  end

  def update
    super
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :profile_public])
  end
end
