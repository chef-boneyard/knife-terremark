$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-terremark/version'

Gem::Specification.new do |s|
  s.name             = 'knife-terremark'
  s.version          = KnifeTerremark::VERSION
  s.platform         = Gem::Platform::RUBY
  s.summary          = "Terremark Cloud Support for Chef's Knife Command"
  s.description      = s.summary
  s.author           = 'Adam Jacob'
  s.email            = 'adam@chef.io'
  s.homepage         = 'https://github.com/chef/knife-terremark'
  s.files            = `git ls-files`.split("\n")

  s.add_dependency 'fog-terremark',     '~> 0.1'
  s.add_dependency 'net-ssh',           '>= 2.0'
  s.add_dependency 'net-ssh-multi',     '>= 1.0'
  s.add_dependency 'net-scp',           '~> 1.1'
  s.add_dependency 'highline'
  
  s.add_development_dependency 'chef',  '~> 12.0', '>= 12.2.1'

  s.require_paths = ['lib']
end
