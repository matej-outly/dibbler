# Maintain your gem's version:
version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.name = "dibbler"
  s.version = version
  s.authors = ["Matěj Outlý"]
  s.email = ["matej.outly@gmail.com"]
  s.summary = "Human readable and localized URLs"
  s.description = "Dibbler is an engine containing entire backend for localized human readable URLs generation and integration."
  s.homepage = "https://github.com/matej-outly/dibbler"
  s.license = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2"
end
