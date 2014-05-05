Rails.application.routes.draw do

  devise_for :users #, :controllers => {:sessions => 'cmtool/sessions', :passwords => 'cmtool/passwords'}
  mount CouchI18n::Engine => "/couch_i18n", as: 'couch_i18n'
  mount Cmtool::Engine => '/cmtool', as: 'cmtool'
end
