class UsersController < ApplicationController

  def index
    scope = User.all
    if params[:desc] or params[:asc]
      scope = scope.asc(params[:asc]) if params[:asc]
      scope = scope.desc(params[:desc]) if params[:desc]
    else
      scope = scope.desc(:score) # order by score as default
    end

    @users = scope
  end

  def show
    @user = User.find(params[:id])
    @maps = @user.maps.desc(:score)
  end
end
