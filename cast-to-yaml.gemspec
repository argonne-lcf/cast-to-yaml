Gem::Specification.new do |s|
  s.name = 'cast-to-yaml'
  s.version = "0.1.2"
  s.author = "Brice Videau"
  s.email = "bvideau@anl.gov"
  s.homepage = "https://github.com/alcf-perfengr/cast-to-yaml"
  s.summary = "Extract information fom a c ast"
  s.files = Dir[ 'cast-to-yaml.gemspec', 'LICENSE', 'lib/**/*.rb' ]
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.3.0'
  s.add_dependency 'cast', '~> 0.3', '>=0.3.0'
end
