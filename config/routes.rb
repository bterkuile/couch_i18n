CouchI18n::Engine.routes.draw do
  root :to => "translations#index"
  resources :translations, constraints: {id: /[\w:\.]+/} do
    collection do
      post :export
      post :import
      delete :destroy_offset
    end
  end
end
