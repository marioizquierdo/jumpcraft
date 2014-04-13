class MapsController < ApplicationController

  # GET /maps/ladder?page=1
  def ladder
    @page_size = 100
    @default_page = SimpleElo.ladder_page_for_score(Map, current_user.score, @page_size) if current_user
    @offset = offset_from_page_param
    @maps = Map.includes(:creator).desc(:score).
      skip(@offset).limit(@page_size) # pagination
  end

  # GET /maps/my_maps?auth_token=1234
  def my_maps
    @maps = Map.where(creator: current_user).desc(:score)
  end

  # GET /maps/suggestions.json?auth_token=1234
  # Get 3 map suggestions: easy, medium or hard,
  # or try to get something as close as possible to that.
  def suggestions
    authenticate_user!

    maps = Map.where(:_id.in => current_user.suggested_map_ids).compact if current_user.suggested_map_ids.present?
    if maps.present? # already suggested maps
      @maps = current_user.suggested_map_ids.map{|id| maps.find{|m| m.id == id} } # ensure same order as in the suggested_map_ids

    else
      skill = current_user.skill_mean
      last_played = Game.last_played_map_ids(current_user, 20) # exclude last 20 maps
      scope = ->(s) do
        if last_played.size < User::TRIAL_GAMES_BEFORE_REGULAR_SUGGESTIONS
          s.trial # if didn't play enough games, show only trial maps
        else
          s.ne(creator_id: current_user.id) # exclude own maps
        end
      end

      map1 = Map.find_near_dificulty skill, :easy,   scope: scope, exclude: last_played
      map2 = Map.find_near_dificulty skill, :medium, scope: scope, exclude: last_played + [map1]
      map3 = Map.find_near_dificulty skill, :hard,   scope: scope, exclude: last_played + [map1, map2]
      @maps = [map1, map2, map3].compact

      # if there are not enough maps on the DB yet, then try again without any filtering
      if @maps.empty?
        map1 = Map.find_near_dificulty skill, :easy
        map2 = Map.find_near_dificulty skill, :medium, exclude: [map1]
        map3 = Map.find_near_dificulty skill, :hard,   exclude: [map1, map2]
        @maps = [map1, map2, map3].compact
      end

      # Save suggestions for next time
      current_user.update_attribute(:suggested_map_ids, @maps.map(&:id))
    end

    render :list
  end

  # GET /maps/near_score.json?auth_token=1234
  # Responds with a list of 50 maps that have a score around the player's score
  def near_score
    authenticate_user!
    score = current_user.score

    maps_below = Map.where(:score.lt => score).asc(:score).limit(25)
    maps_over = Map.where(:score.gte => score).asc(:score).limit(25)

    @maps = maps_below.to_a + maps_over.to_a
    @plays_count = get_plays_count_for(current_user, @maps)
    render :list
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

private

  # Return a hash where keys are maps ids,
  # and values are the number of times the user played each map.
  def get_plays_count_for(user, maps)
    map = "function() { emit(this.map_id, 1); }"
    reduce = "function(key, result) { return result.length; }"
    plays = {}
    Game.all
    Game.user(user).maps(maps).map_reduce(map, reduce).out(inline: true).each do |rd|
      plays[rd['_id']] = rd['value'].to_i
    end
    plays
  end
end
