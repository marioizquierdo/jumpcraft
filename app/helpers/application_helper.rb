module ApplicationHelper


  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  # Return page from params[:page] as integer, being 1 the default first page
  def current_page
    [(params[:page] || @default_page || 1).to_i, 1].max # ensure positive integer
  end

end
