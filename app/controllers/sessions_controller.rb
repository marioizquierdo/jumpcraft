class SessionsController < Devise::SessionsController

  def create
    resource = warden.authenticate!(scope: resource_name, recall: "#{controller_path}#new")
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)

    respond_to do |format|
      format.html do
        respond_with resource, location: redirect_location(resource_name, resource)
      end
      format.json do
        render json: { success: true, auth_token: current_user.authentication_token }.to_json, status: :ok
      end
    end
  end

end