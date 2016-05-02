source "http://rubygems.org"

gem 'rails', '~> 4.2.0' #     :git => 'git://github.com/rails/rails.git'
#gem 'couch_potato' , github: 'bterkuile/couch_potato'
gem 'simply_stored' , github: 'bterkuile/simply_stored'
#gem 'haml-rails'
gem 'kaminari'
#gem 'tinymce-rails'
group :assets do
  gem 'jquery-rails'
  gem 'jquery-ui-rails'
  gem 'sprockets-rails' #, '~> 2.1'

  gem 'foundation-rails'
  #gem 'bourbon'
  gem 'sass-rails' #, '4.0.2'
  gem 'uglifier'
  gem 'coffee-rails'
end

group :development do
  gem 'paperclip'
  gem 'cmtool', github: 'bterkuile/cmtool'
  gem 'devise'
  gem 'devise_simply_stored', github: 'bterkuile/devise_simply_stored'
  gem 'orm_adapter', github: 'bterkuile/orm_adapter'
end

group :test do
  gem 'steak'
  gem 'devise'
  gem 'orm_adapter', github: 'bterkuile/orm_adapter'
  gem 'devise_simply_stored', github: 'bterkuile/devise_simply_stored'
  gem 'factory_girl_rails'
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-doc'
end
