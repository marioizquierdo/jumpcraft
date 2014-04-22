class MapsController < ApplicationController

  # GET /maps/ladder?page=1
  def ladder
    @page_size = 100
    @default_page = RatingSystem.ladder_page_for_score(Map, current_user.score, @page_size) if current_user
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

    # Check if there are cached suggestions on the user
    if current_user.suggested_map_ids.present?
      maps = Map.where(:_id.in => current_user.suggested_map_ids).to_a.compact
    else
      maps = nil
    end

    # Use cached suggestions if present
    if maps.present?
      @maps = current_user.suggested_map_ids.map{|id| maps.find{|m| m.id == id} } # ensure same order as in the suggested_map_ids

    # If no cached suggestions, then load new suggestions
    else
      @last_played = Game.last_played_map_ids(current_user, 20) # exclude last 20 played maps

      @maps = get_trial_suggestions || get_standard_suggestions || get_unfiltered_suggestions || []
      @maps = @maps.sort_by(&:skill_mean) # Order by difficulty

      # Cache new suggestions
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

  # Suggestions are some hand-picked trial maps for the first game experience
  def get_trial_suggestions
    case @last_played.size
    when 0
      trials_by_skill 0 => :very_easy, 2 => :medium,    6 => :hard
    when 1
      trials_by_skill 0 => :very_easy, 2 => :easy,      6 => :medium,  10 => :hard
    when 2
      trials_by_skill 0 => :trivial,   2 => :very_easy, 6 => :easy,    10 => :medium, 12 => :hard
    when 3
      trials_by_skill 2 => :trivial,   6 => :very_easy, 10 => :medium, 12 => :medium, 14 => :hard,   16 => :hard
    when 4
      trials_by_skill 6 => :very_easy, 7 => :easy,      10 => :easy,   12 => :medium, 14 => :medium, 16 => :hard,   18 => :hard
    when 5
      trials_by_skill 7 => :very_easy, 9 => :easy,      10 => :easy,   12 => :medium, 14 => :medium, 16 => :hard,   18 => :hard, 27 => :very_hard
    when 6
      trials_by_skill 9 => :very_easy, 10 => :easy,     12 => :easy,   14 => :medium, 16 => :medium, 18 => :medium, 27 => :hard, 35 => :very_hard, 38 => :very_hard
    else
      nil # if user already played more than 6 games, then return nil (will get delegated to get_standard_suggestions)
    end
  end

  # Automatic suggestions, based on the current user skill
  def get_standard_suggestions
    without_own_maps = ->(s){ s.ne(creator_id: current_user.id) } # exclude own maps
    map1 = Map.find_near_dificulty current_user.skill_mean, :easy,   scope: without_own_maps, exclude: @last_played
    map2 = Map.find_near_dificulty current_user.skill_mean, :medium, scope: without_own_maps, exclude: @last_played + [map1]
    map3 = Map.find_near_dificulty current_user.skill_mean, :hard,   scope: without_own_maps, exclude: @last_played + [map1, map2]
    maps = [map1, map2, map3].compact
    maps.empty? ? nil : maps
  end

  # Fallback solution to make sure we always have some suggestions
  def get_unfiltered_suggestions
    map1 = Map.find_near_dificulty current_user.skill_mean, :easy
    map2 = Map.find_near_dificulty current_user.skill_mean, :medium, exclude: [map1]
    map3 = Map.find_near_dificulty current_user.skill_mean, :hard,   exclude: [map1, map2]
    maps = [map1, map2, map3].compact
    maps.empty? ? nil : maps
  end

  # Helper to load trial maps by skill_mean, and then assign relative_difficulty
  def trials_by_skill(skill_difficulty_mapping)
    skill_means = skill_difficulty_mapping.keys
    maps = Map.trial.nin(_id: @last_played).in(skill_mean: skill_means).limit(3).to_a # load trials
    maps.each do |m|
      m.relative_difficulty = skill_difficulty_mapping[m.skill_mean.to_i] # assign relative_difficulty
    end
    maps
  end
end
