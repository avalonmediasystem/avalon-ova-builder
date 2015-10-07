# spec/spec_helper.rb
require 'rack/test'
require 'rspec'
require 'byebug'
require 'vcr'

require 'GithubChecker'
require 'Builder'

require File.expand_path '../../my-app.rb', __FILE__

ENV['RACK_ENV'] = 'test'
$LOAD_PATH << '../lib'
module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

# For RSpec 2.x
RSpec.configure { |c| c.include RSpecMixin }

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock # or :fakeweb
end
