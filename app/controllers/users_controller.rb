class UsersController < ApplicationController

  def index
    scope = User.all
    scope = scope.desc(params[:desc]) if params[:desc]
    scope = scope.asc(params[:asc]) if params[:asc]
    @users = scope
  end

  def show
    @user = User.find(params[:id])
    @maps = @user.maps.desc(:score)
  end
end
