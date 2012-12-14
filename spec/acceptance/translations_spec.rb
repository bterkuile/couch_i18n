require 'acceptance/acceptance_helper'

feature 'Translations', %q{
  In order have dynamic translations
  As a user
  I want to be able to manage translations
} do

  scenario 'root path should be translations index' do
    visit '/couch_i18n'
    page.should have_content 'No translations found'
  end

end
