class MapsController < ApplicationController

  # GET /maps/ladder
  def ladder
    @maps = Map.includes(:creator).desc(:score)
  end

  # GET /maps/suggestions.json?auth_token=1234
  # Get 3 map suggestions: easy, medium or hard,
  # or try to get something as close as possible to that.
  def suggestions
    authenticate_user!
    score = current_user.score
    difficulty_step = 32 # how many points difference for each category
    easy_score   = score - difficulty_step
    medium_score = score
    hard_score   = score + difficulty_step

    # Find an easy map
    Map.find_near_score(easy_score, difficulty_step/2)

  end

  # GET /maps/near_score.json?auth_token=1234
  # Responds with a list of 50 maps that have a score around the player's score
  def near_score
    authenticate_user!
    score = current_user.score
    maps_below = Map.where(:score.lt => score).asc(:score).limit(25)
    maps_over = Map.where(:score.gte => score).asc(:score).limit(25)
    @maps = maps_below.to_a + maps_over.to_a

    render json: { maps: @maps }
  end

  # GET /maps/:id
  def show
    @map = Map.find(params[:id])
  end

  # POST /maps.json
  def create
    authenticate_user!
    @map = Map.create_for_user(current_user, params[:map])
    render json: {ok: true}
  end
end
