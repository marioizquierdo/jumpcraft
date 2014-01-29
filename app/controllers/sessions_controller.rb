class SessionsController < Devise::SessionsController

  # login
  def create
    resource = warden.authenticate!(scope: resource_name, recall: "#{controller_path}#new")
    sign_in(resource_name, resource)

    respond_to do |format|
      format.html do
        redirect_to after_sign_in_path_for(resource)
      end
      format.json do
        render json: { success: true, user: resource, auth_token: current_user.authentication_token }, status: :ok
      end
    end
  end

end