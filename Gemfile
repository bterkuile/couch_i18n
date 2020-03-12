source "http://rubygems.org"

gem 'rails', '~> 6.0.2' #     :git => 'git://github.com/rails/rails.git'
gem 'couch_potato' , github: 'langalex/couch_potato', branch: :master
gem 'simply_stored' , github: 'bterkuile/simply_stored', branch: :master
#gem 'haml-rails'
gem 'kaminari'
#gem 'tinymce-rails'
group :assets do
  gem 'jquery-rails'
  gem 'jquery-ui-rails'
  gem 'sprockets-rails' #, '~> 2.1'

  gem 'foundation-rails', '~> 5.5'
  #gem 'bourbon'
  gem 'sass-rails' #, '4.0.2'
  gem 'uglifier'
  gem 'coffee-rails'
  gem 'ace-rails-ap'
  gem 'pickadate-rails'
  gem 'font-awesome-rails'
  gem 'tinymce-rails'
end

group :development do
  gem 'paperclip'
  gem 'cmtool', github: 'bterkuile/cmtool', branch: :master
  gem 'devise'
  gem 'devise_simply_stored', github: 'bterkuile/devise_simply_stored', branch: :master
  gem 'orm_adapter', github: 'bterkuile/orm_adapter', branch: :master
end

group :test do
  gem 'steak'
  gem 'devise'
  gem 'orm_adapter', github: 'bterkuile/orm_adapter', branch: :master
  gem 'devise_simply_stored', github: 'bterkuile/devise_simply_stored', branch: :master
  gem 'factory_girl_rails'
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-doc'
end
