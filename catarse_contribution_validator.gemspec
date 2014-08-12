$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "catarse_contribution_validator/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "catarse_contribution_validator"
  s.version     = CatarseContributionValidator::VERSION
  s.authors     = ["Antonio Roberto"]
  s.email       = ["forevertonny@gmail.com"]
  s.homepage    = "http://github.com/catarse/catarse_contribution_validator"
  s.summary     = "Just a Raketask to check integrity of contributions"
  s.description = "Just a Raketask to check integrity of contributions"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.0.0"
end
