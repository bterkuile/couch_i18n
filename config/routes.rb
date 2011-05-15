CouchI18n::Engine.routes.draw do
  root :to => "stores#index"
  resources :stores
end
