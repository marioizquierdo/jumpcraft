class UsersController < ApplicationController
  respond_to :html, :json

  def index
    @users = User.all
    respond_with @users
  end

  def show
    @user = User.find(params[:id])
    respond_with @user
  end

  def test
    authenticate_user!
    render :json => {ok: true}
  end

end
