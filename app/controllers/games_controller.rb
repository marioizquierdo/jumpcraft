class GamesController < ApplicationController
  before_filter :authenticate_user!

  # POST /games/start.json
  # params {map_id=aa99}
  def start
    # Find map and player
    map = Map.find(params[:map_id])
    player = current_user

    # If the user didn't properly finish any of the previous games,
    # finish them with a lose. He probably was trying to cheat.
    if game = Game.user(player).unfinished.first
      game.map_defeated = false # player lose
      game.finish_and_save!
      render json: {
        error: 'Unfinished Game Found',
        error_message: 'There was an unfinished game, that was fast-finished with the player being defeated. Please try again.',
        player_new_score: player.score
      }, status: 403
      return
    end

    # Create new game (mark of game in progess)
    Game.create user: player, map: map, finished: false

    render json: { success: true }
  end

  # POST /games/finish.json
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
end
