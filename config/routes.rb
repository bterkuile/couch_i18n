CouchI18n::Engine.routes.draw do
  root :to => "stores#index"
  resources :stores do
    collection do
      post :export
      post :import
      delete :destroy_offset
    end
  end
end
