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
    scoped = Game.where user_id: user.id, :map_id.in => maps.collect(&:id)

    map = "function() { emit(this.map_id, 1); }"
    reduce = "function(key, result) { return result.length; }"
    vals = scoped.map_reduce(map, reduce).out(inline: 1)

    plays = {}
    vals.each do |rd|
      plays[rd['_id']] = rd['value'].to_i
    end
    plays
  end

  # Suggestions are some hand-picked trial maps for the first game experience
  def get_trial_suggestions
    case @last_played.size
    when 0
      load_trials({
        'San Francisco'       => :very_easy,
        'The Bunker'          => :very_easy,
        'Caravel Ships'       => :easy,
      })
    when 1
      load_trials({
        'San Francisco'       => :very_easy,
        'The Bunker'          => :very_easy,
        'Caravel Ships'       => :easy,
        'Tower in the Castle' => :medium,
      })
    when 2
      load_trials({
        'San Francisco'       => :very_easy,
        'Caravel Ships'       => :very_easy,
        'Tower in the Castle' => :easy,
        'Cat Mountain Climb'  => :medium,
        'Moonlit Woods'       => :medium,
      })
    when 3
      load_trials({
        'San Francisco'       => :very_easy,
        'Tower in the Castle' => :easy,
        'Cat Mountain Climb'  => :easy,
        'Moonlit Woods'       => :easy,
        'Egypt Pyramid'       => :medium,
        'The Cave'            => :medium,
      })
    when 4
      load_trials({
        'Tower in the Castle' => :very_easy,
        'Cat Mountain Climb'  => :easy,
        'Moonlit Woods'       => :easy,
        'Egypt Pyramid'       => :medium,
        'The Cave'            => :medium,
        'Cyberpunk Ruins'     => :hard,
        'Steamport Town'      => :hard,
      })
    when 5
      load_trials({
        'Cat Mountain Climb'  => :very_easy,
        'Moonlit Woods'       => :easy,
        'Egypt Pyramid'       => :easy,
        'The Cave'            => :easy,
        'Cyberpunk Ruins'     => :medium,
        'Steamport Town'      => :medium,
        'Find the Dragon'     => :hard,
        'Star Hopping'        => :hard,
      })
    when 6
      load_trials({
        'Cat Mountain Climb'  => :very_easy,
        'Moonlit Woods'       => :very_easy,
        'Egypt Pyramid'       => :easy,
        'The Cave'            => :easy,
        'Cyberpunk Ruins'     => :medium,
        'Steamport Town'      => :medium,
        'Find the Dragon'     => :hard,
        'Star Hopping'        => :hard,
        'Shadow of Valus'     => :very_hard,
        'The Cube'            => :very_hard,
      })
    when 7
      load_trials({
        'Tower in the Castle' => :easy,
        'Moonlit Woods'       => :very_easy,
        'Egypt Pyramid'       => :easy,
        'The Cave'            => :easy,
        'Cyberpunk Ruins'     => :medium,
        'Steamport Town'      => :medium,
        'Find the Dragon'     => :hard,
        'Star Hopping'        => :hard,
        'Shadow of Valus'     => :very_hard,
        'The Cube'            => :very_hard,
        'Temple City'         => :very_hard,
      })
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

  # Helper to load trial maps by skill_mean, and then assign relative_difficulty.
  # easier_or_harder is to select the most difficult ones or the easier ones if there are more than 3 results.
  def load_trials(names_to_difficulties_map)
    names = names_to_difficulties_map.keys
    maps = Map.trial # only trials
    maps = maps.in(name: names) # filter by name
    maps = maps.nin(_id: @last_played) # take away already played maps

    # order by difficulty, depending on the win/loss ratio
    if @last_played.size > 0
      win_loss_ratio = number_of_last_played_wins.to_f / @last_played.size
      maps = maps.order_by(skill_mean: win_loss_ratio > 0.5 ? 'desc' : 'asc')
    end

    maps = maps.limit(3).to_a # load 3 trials
    maps.each do |m|
      m.trial_difficulty = names_to_difficulties_map[m.name] # assign relative_difficulty
    end
    maps
  end

  # Load games by @last_played and sum the number of times the map was defeated
  def number_of_last_played_wins
    games = Game.last_played_by(@current_user, 20).only(:map_defeated).to_a # load games
    games.inject(0){|sum, game| game.map_defeated ? sum + 1 : sum } # sum number of times the map was defeated == number of wins
  end
end
