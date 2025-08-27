# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.
$:.push File.expand_path("../lib", __FILE__)
require 'couch_i18n/version'

Gem::Specification.new do |s|
  s.name = "couch_i18n"
  s.version = CouchI18n::VERSION

  s.authors = ["Benjamin ter Kuile"]
  s.email = %q{bterkuile@gmail.com}
  s.homepage = %q{http://github.com/bterkuile/couch_i18n}
  s.rubyforge_project = "couch_i18n"
  s.summary = "couch_i18n is an in database storage for I18n translations, tested for rails, with online management views"
  s.description = "couch_i18n is an in database storage for I18n translations, tested for rails, with online management views"
  s.files = Dir["lib/**/*"] + Dir["app/**/*"] + Dir["config/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.add_dependency 'activemodel' #, '>= 3'
  s.add_dependency 'simply_stored'
  s.version = "2.0.0"
end
