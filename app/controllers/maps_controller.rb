class MapsController < ApplicationController

  def index
    @maps = Map.all
  end

  def show
    @map = Map.find(params[:id])
  end

  def create
    authenticate_user!
    args = params[:map].merge(creator: current_user)
    @map = Map.create!(args)
    render json: {ok: true}
  end

end
