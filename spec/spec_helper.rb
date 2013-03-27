$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'mocha/api'
require 'webmock/rspec'

require 'tent-client'

ENV['RACK_ENV'] ||= 'test'

RSpec.configure do |config|
  config.mock_with :mocha
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
