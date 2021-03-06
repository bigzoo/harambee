Rails.application.routes.draw do
  resources :home, only: :index
  root 'home#index'
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'
  resources :sessions, only: [:create, :destroy]
  resources :user_harambees, path: :harambees do
    resources :contribute, only: :index
  end
  post '/contribute/transaction', to: 'contribute#transaction'
  post '/contribute/callback', to: 'contribute#callback'
  resources :dashboard, only: :index
  resources :profile, only: :index
  resources :login, only: :index
end
