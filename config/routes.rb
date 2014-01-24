Infiltration::Application.routes.draw do
  authenticated :user do
    root to: 'home#index'
  end
  root to: "home#index"
  devise_for :users, token_authentication_key: 'auth_token', controllers: {sessions: 'sessions'}

  get '/users/ladder'     => 'users#ladder', as: 'users_ladder'
  get '/users/:id'        => 'users#show', as: 'user'

  get '/maps/ladder'      => 'maps#ladder', as: 'maps_ladder'
  get '/maps/my_maps'     => 'maps#my_maps', as: 'maps_my_maps'
  get '/maps/suggestions' => 'maps#suggestions', as: 'maps_suggestions'
  get '/maps/near_score'  => 'maps#near_score', as: 'maps_near_score'
  get '/maps/:id'         => 'maps#show', as: 'map'
  post '/maps'            => 'maps#create'

  get '/games/my_games'   => 'games#my_games'
  post '/games/start'     => 'games#start'
  post '/games/finish'    => 'games#finish'
end