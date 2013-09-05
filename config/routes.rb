Infiltration::Application.routes.draw do
  authenticated :user do
    root to: 'home#index'
  end
  root to: "home#index"
  devise_for :users, token_authentication_key: 'auth_token', controllers: {sessions: 'sessions'}

  get '/users' => 'users#index', as: 'users'
  get '/users/:id' => 'users#show', as: 'user'

  get '/maps/ladder' => 'maps#ladder', as: 'maps_ladder'
  get '/maps/near_score' => 'maps#near_score', as: 'maps_near_score'
  get '/maps/:id' => 'maps#show', as: 'map'
  post '/maps' => 'maps#create'

  post '/games/start'  => 'games#start'
  post '/games/finish' => 'games#finish'
end