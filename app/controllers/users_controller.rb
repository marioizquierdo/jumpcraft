class UsersController < ApplicationController


  # GET /users/ladder?page=1
  def ladder
    @page_size = 100
    @default_page = RatingSystem.ladder_page_for_score(User, current_user.score, @page_size) if current_user
    @offset = offset_from_page_param

    @users = User.order_by(score: -1, coins: -1). # ranked by score, and then by coins when same score
      skip(@offset).limit(@page_size) # pagination
  end

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    @maps = @user.maps.desc(:score).entries
  end

end
