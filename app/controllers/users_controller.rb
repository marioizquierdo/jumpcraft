class UsersController < ApplicationController


  # GET /users/ladder
  def ladder
    @users = User.desc(:score)
  end

  def show
    @user = User.find(params[:id])
    @maps = @user.maps.desc(:score)
  end
end
