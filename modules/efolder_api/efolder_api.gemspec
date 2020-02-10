# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require "efolder_api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|

  # s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  # s.test_files = Dir['spec/**/*']

  # s.add_dependency 'rails', '~> 5.2.3'

  # s.add_development_dependency 'rspec-rails'
  spec.name        = "efolder_api"
  spec.version     = EfolderApi::VERSION
  spec.authors     = ["Keith Adkins"]
  spec.email       = ["keith.adkins@adhocteam.us"]
  spec.homepage    = "https://api.va.gov/services/efolder/docs/v0"
  spec.summary     = "VBMS eFolder API"
  spec.description = "Proxies eFolder API requests to VBMS eFolder SOAP WSS"
  spec.license     = "CC0"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  spec.test_files = Dir['spec/**/*']

  spec.add_dependency 'carrierwave-aws'
  spec.add_dependency "rails", "~> 5.2.4", ">= 5.2.4.1"
  spec.add_dependency 'sidekiq'

  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rspec-rails'
end
