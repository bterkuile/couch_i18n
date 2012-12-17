# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'rspec/autorun'
require 'factory_girl'
require 'capybara/rspec'
require 'devise'
#require 'cmtool'

class CouchI18n::Translation
  def inspect
    "<#{key} ..>"
  end
end

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }
Dir[File.join(ENGINE_RAILS_ROOT, "spec/factories/**/*.rb")].each {|f| require f }

I18n.locale = :en
#Devise.stretches = 1
#Capybara.default_driver = :selenium
RSpec.configure do |config|
  config.mock_with :rspec
  config.include FactoryGirl::Syntax::Methods
  #config.include CompanyFactory
  #config.include Cmtool::Engine.routes.url_helpers
  #config.include Devise::TestHelpers, :type => :controller
  #config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = true
  config.render_views = true

  config.before :each do
    CouchPotato.couchrest_database.recreate!
  end

  config.before :all, type: :controller do
    #render_views 
  end

  config.before :all do
  end
  config.before :each, type: :request do
    #Capybara.current_driver = :selenium
    #sign_in_user_through_request
  end
  config.after :each, type: :request do
    visit "/users/sign_out"
  end
  def sign_in_user_through_request
    visit "/users/sign_in"
    fill_in 'user[email]', with: @user.email
    fill_in 'user[password]', with: @user.password
    click_on 'Sign in'
  end
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
end
