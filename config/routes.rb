CouchI18n::Engine.routes.draw do
  root :to => "translations#index"
  # allow escaped forms (%+) and unescaped forms (: ) (note the space!!) as id
  resources :translations, constraints: {id: /[\w:% \.\+]+/} do
    collection do
      post :export
      post :import
      delete :destroy_offset
    end
  end
end
