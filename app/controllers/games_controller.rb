class GamesController < ApplicationController
  before_filter :authenticate_user!

  # GET /games/my_games
  def my_games
    @page_size = 100
    @offset = offset_from_page_param
    @games = Game.user(current_user).includes(:map).desc(:_id). # order by id works ok to get the last inserted ones
      skip(@offset).limit(@page_size) # pagination
  end

  # POST /games/start.json?auth_token=1234
  # params {map_id=aa99}
  def start
    # Find map and player
    map = Map.find(params[:map_id])
    player = current_user

    # If the user didn't properly finish any of the previous games, finish them with a lose
    if game = Game.user(player).unfinished.first
      game.map_defeated = false # player lose, he was trying to cheat.
      game.finish_and_save!
      render json: {
        error: 'Unfinished Game Found',
        error_message: 'There was an unfinished game, that was fast-finished with the player being defeated. Please try again.',
        player_new_score: player.score
      }, status: 403
      return
    end

    # Make sure that the game is in one of the suggested maps
    if not (player.suggested_map_ids || []).include?(map.id)
      render json: {
        error: 'Not a suggested map',
        error_message: 'Can only play maps suggested by the system. Visit /maps/suggestions first.',
      }, status: 403
      return
    end

    # Create new game (mark of game in progess)
    Game.create user: player, map: map, finished: false

    render json: { success: true }
  end

  # POST /games/finish.json?auth_token=1234
  # params {map_defeated=true, collected_coins=99}
  # After playing a map (not practice), update map/user scores
  def finish

    # Check params
    if !params.include?(:map_defeated) or !params.include?(:collected_coins)
      render json: {error: 'params map_defeated and collected_coins are mandatory'}, status: 403
      return
    end
    map_defeated = params[:map_defeated] == 'true'
    collected_coins = params[:collected_coins].to_i

    # Load game in progress
    game = Game.user(current_user).unfinished.first
    if !game
      render json: { error: 'Unfinished Game Not Found', error_message: 'Can not finish a game that was not started.' }, status: 403
      return
    end

    # Finish and update game, user and map
    game.map_defeated = map_defeated
    game.coins = collected_coins
    game.finish_and_save!

    render json: { player_new_score: game.user.score, map_new_score: game.map.score }
  end

  # POST /games/update_tutorial.json?auth_token=1234
  # params {tutorial=99}
  # After completing a tutorial, update the user.tutorial field
  def update_tutorial
    current_user.update_attribute(:tutorial, params[:tutorial].to_i)
    render json: { sucess: true, user_tutorial: current_user.tutorial }
  end
end
