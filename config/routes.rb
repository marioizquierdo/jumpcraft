Infiltration::Application.routes.draw do
  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users, token_authentication_key: 'auth_token', controllers: {sessions: 'sessions'}

  resources :users, only: [:index, :show]
  resources :maps, only: [:index, :show, :create]

  post '/games/start'  => 'games#start'
  post '/games/finish' => 'games#finish'
end