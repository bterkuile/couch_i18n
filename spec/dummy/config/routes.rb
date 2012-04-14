Rails.application.routes.draw do

  mount CouchI18n::Engine => "/couch_i18n"
end
