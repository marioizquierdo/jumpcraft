class UsersController < ApplicationController


  # GET /users/ladder?page=1
  def ladder
    @page_size = 100
    @offset = offset_from_page_param
    @users = User.desc(:score).
      skip(@offset).limit(@page_size) # pagination
  end

  def show
    @user = User.find(params[:id])
    @maps = @user.maps.desc(:score)
  end
end
