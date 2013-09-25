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

    distance = 16 # score distance used to define each map difficulty category
    very_easy_score_low = score - 7*distance
    easy_score_low = score - 3*distance
    easy_score_hig = score - distance
    hard_score_low = score + distance
    hard_score_hig = score + 3*distance
    very_hard_score_hig = score + 7*distance

    easy   = Map.find_near_score(easy_score_low, easy_score_hig)
    medium = Map.find_near_score(easy_score_hig + 1, hard_score_low - 1)
    hard   = Map.find_near_score(hard_score_low, hard_score_hig)

    if not easy
      very_easy = Map.find_near_score(very_easy_score_low, easy_score_low)
    end

    if not hard
      very_hard = Map.find_near_score(hard_score_hig, very_hard_score_hig)
      if not very_hard
        other_medium = Map.find_near_score(easy_score_hig + 1, hard_score_low - 1)
        other_medium = nil if other_medium == medium
      end
    end

    if not very_easy or not very_hard
      other_medium = Map.find_near_score(easy_score_hig + 1, hard_score_low - 1)
      other_medium = nil if other_medium == medium
    end

    @maps = [[:very_easy, very_easy], [easy: easy], [medium: medium], [medium: other_medium], [hard: hard], [very_hard: very_hard]]
    @maps.reject!{|m| m[1] == nil}

    render json: { maps: @maps}
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
