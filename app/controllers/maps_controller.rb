class MapsController < ApplicationController

  # GET /maps
  # Used to check the ladder of maps
  def index
    scope = Map.all

    # Filter by creator_id
    if params[:creator_id]
      scope = scope.where(creator_id: params[:creator_id])
    end

    # Order
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
end
