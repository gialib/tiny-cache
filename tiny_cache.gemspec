$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "tiny_cache/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "tiny_cache"
  s.version     = TinyCache::VERSION
  s.authors     = ["happy"]
  s.email       = ["andywang7259@gmail.com"]
  s.homepage    = "http://blogsoso.net"
  s.summary     = "Summary of TinyCache."
  s.description = "Description of TinyCache."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails"

  s.add_development_dependency "sqlite3"
end
