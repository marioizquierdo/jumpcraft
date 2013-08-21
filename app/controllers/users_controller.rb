class UsersController < ApplicationController

  def index
    scope = User.all
    if params[:desc]
      scope = scope.desc(params[:desc])
    else
      score = scope.desc(:score, :coins) # order by score as default
    end
    scope = scope.asc(params[:asc]) if params[:asc]
    @users = scope
  end

  def show
    @user = User.find(params[:id])
    @maps = @user.maps.desc(:score)
  end
end
