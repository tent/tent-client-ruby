# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tent-client/version'

Gem::Specification.new do |gem|
  gem.name          = "tent-client"
  gem.version       = TentClient::VERSION
  gem.authors       = ["Jonathan Rudenberg", "Jesse Stuart"]
  gem.email         = ["jonathan@titanous.com", "jesse@jessestuart.ca"]
  gem.description   = %q{Tent Protocol client}
  gem.summary       = %q{Tent Protocol client}
  gem.homepage      = "https://tent.io"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'yajl-ruby'
  gem.add_runtime_dependency 'faraday', '0.8.4'
  gem.add_runtime_dependency 'faraday_middleware', '0.8.8'
  gem.add_runtime_dependency 'faraday_middleware-multi_json'
  gem.add_runtime_dependency 'nokogiri'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'webmock'
end
