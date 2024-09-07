Rails.application.routes.draw do
  post 'register', to: 'users#register'
  post 'login', to: 'users#login'
  delete 'logout', to: 'users#logout'
  post 'admin/login', to: 'users#admin_login' 
  get 'profile', to: 'users#show'
  put 'profile', to: 'users#update'
  namespace :admin do
    resources :users, only: [:index, :create,:update] do
      member do
        patch 'block'
        patch 'unblock'
      end
    end
  end
end