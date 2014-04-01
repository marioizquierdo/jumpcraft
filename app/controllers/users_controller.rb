class UsersController < ApplicationController


  # GET /users/ladder?page=1
  def ladder
    @page_size = 100
    @default_page = SimpleElo.ladder_page_for_score(User, current_user.score, @page_size) if current_user
    @offset = offset_from_page_param

    @users = User.desc(:score).
      skip(@offset).limit(@page_size) # pagination
  end

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    @maps = @user.maps.desc(:score).entries
  end

end
