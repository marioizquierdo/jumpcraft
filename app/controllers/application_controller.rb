class ApplicationController < ActionController::Base
  # protect_from_forgery # skip csrf token verification to make more easy to login from Flash
  before_action :configure_permitted_parameters, if: :devise_controller?

protected

  # Rails 4 moved the parameter sanitization from the model to the controller, causing Devise to handle this concern at the controller as well.
  # This allows to signup users with the extra parameter: name
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  # Calculate the @offset used for Mongoid skip from params[:page] and @page_size
  # Note: set @page_size before if you don't want to use default page size
  def offset_from_page_param
    page = view_context.current_page # from application_helper.rb
    page_size = @page_size || 100
    (page - 1) * page_size
  end
end
