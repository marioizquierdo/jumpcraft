Infiltration::Application.routes.draw do
  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users, token_authentication_key: 'auth_token', controllers: {sessions: 'sessions'}
  resources :users
  match 'users_test' => 'users#test'
end