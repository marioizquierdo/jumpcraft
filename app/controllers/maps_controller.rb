class MapsController < ApplicationController

  # GET /maps
  def index
    @maps = Map.all
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

  # PUT /maps/:id/game.json [map_defeated=true]
  # After playing a map (not practice), update map/user scores
  def create_game
    map = Map.find(params[:id])
    player = current_user
    if params[:map_defeated]
      winner = player; loser = map
    else
      winner = map; loser = player
    end
    SimpleELO.assign_new_scores!(winner, loser)
    winner.save!
    loser.save!
    render json: { player_new_score: player.score, map_new_score: map.score }
  end

end
