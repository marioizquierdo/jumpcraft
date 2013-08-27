class MapsController < ApplicationController

  # GET /maps
  # Used to check the ladder of maps
  def index
    scope = Map.all
    if params[:desc] or params[:asc]
      scope = scope.asc(params[:asc]) if params[:asc]
      scope = scope.desc(params[:desc]) if params[:desc]
    else
      scope = scope.desc(:score) # order by score as default
    end

    scope = scope.includes(:creator)
    @maps = scope
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

  # POST /maps/:id/game.json
  # POST params [map_defeated=true, collected_coins=99]
  # After playing a map (not practice), update map/user scores
  def game
    authenticate_user!

    # Check params
    if !params.include?(:map_defeated) or !params.include?(:collected_coins)
      render json: {error: 'params map_defeated and collected_coins are mandatory'}, status: :forbidden # 403
    end
    map_defeated = params[:map_defeated] == 'true'
    collected_coins = params[:collected_coins].to_i

    # Find map and player
    map = Map.find(params[:id])
    player = current_user

    # Create game record
    Game.create user: player, map: map, map_defeated: map_defeated, coins: collected_coins,
      user_score: player.score,
      map_score: map.score,
      user_played_games: user.played_games,
      map_played_games: map.played_games

    # Assign new scores
    winner, loser = map_defeated ? [player, map] : [map, player]
    SimpleELO.assign_new_scores!(winner, loser)

    # Update user stats
    player.coins += collected_coins
    player.played_games += 1
    player.won_games += 1 if map_defeated

    # Update map stats
    map.played_games += 1
    map.won_games += 1 unless map_defeated

    # Save
    player.save!
    map.save!

    # Response
    render json: { player_new_score: player.score, map_new_score: map.score }
  end

end
