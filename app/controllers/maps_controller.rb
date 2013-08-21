class MapsController < ApplicationController

  # GET /maps
  # Used to check the ladder of maps
  def index
    scope = Map.all
    if params[:desc]
      scope = scope.desc(params[:desc])
    else
      score = scope.desc(:score) # order by score as default
    end
    scope = scope.asc(params[:asc]) if params[:asc]
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

    # Find map and player
    map = Map.find(params[:id])
    player = current_user

    # Assign new scores
    winner, loser = params[:map_defeated] ? [player, map] : [map, player]
    SimpleELO.assign_new_scores!(winner, loser)

    # Update user stats
    player.coins += params[:collected_coins].to_i
    player.played_games += 1
    player.won_games += 1 if params[:map_defeated]

    # Update map stats
    map.played_games += 1
    map.won_games += 1 unless params[:map_defeated]

    # Save
    player.save!
    map.save!

    # Response
    render json: { player_new_score: player.score, map_new_score: map.score }
  end

end
