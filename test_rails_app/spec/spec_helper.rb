# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

module SpecHelperMethods
  def assert_a_tag_with_get_args(
    content, href_base, href_get_args, response_body
  )
    regex = %r|<a href="#{ href_base }\?([^"]*)"[^>]*>#{ content }</a>|
    assert(
      response_body =~ regex,
      "#{response_body.inspect} expected to match #{regex.inspect}"
    )
    assert_get_args_equal( href_get_args, $1.gsub( /&amp;/, '&' ) )
  end
  
  def assert_no_a_tag_with_get_args(
    content, href_base, href_get_args, response_body
  )
    regex = %r|<a href="#{ href_base }\?([^"]*)"[^>]*>#{ content }</a>|
    if response_body =~ regex
      get_args_string = $1.gsub( /&amp;/, '&' )
      response_h = HashWithIndifferentAccess.new
      CGI::parse( get_args_string ).each do |key, values|
        response_h[key] = values.first
      end
      if href_get_args.size == response_h.size
        raise if href_get_args.all? { |key, value|
          response_h[key] == value
        }
      end
    end
  end
  
  def assert_get_args_equal( expected_hash, get_args_string )
    response_h = HashWithIndifferentAccess.new
    CGI::parse( get_args_string ).each do |key, values|
      response_h[key] = values.first
    end
    assert_equal(
      expected_hash.size, response_h.size,
      "<#{ expected_hash.inspect }> expected but was\n<#{ response_h.inspect }>."
    )
    expected_hash.each do |key, value|
      assert_equal( value, response_h[key] )
    end
  end

  def random_word( length = 25 )
    letters = 'abcdefghijklmnopqrstuvwxyz_'.split //
    ( 1..length ).to_a.map { letters[rand(letters.size)] }.join( '' )
  end
end

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
  
  include SpecHelperMethods
end

class CacheStoreStub
  def initialize
    flush
  end
  
  def expires_in(key)
    @expirations[key.to_s]
  end
  
  def flush
    @cache = {}
    @expirations = {}
    @raise_on_write = false
  end
  
  def raise_on_write
    @raise_on_write = true
  end
  
  def read(key, options = nil)
    @cache[key.to_s]
  end
  
  def write(key, value, options = nil)
    raise if @raise_on_write
    @cache[key.to_s] = value
    @expirations[key.to_s] = options[:expires_in]
  end
end

$cache = CacheStoreStub.new

module Rails
    mattr_accessor :cache
  self.cache = $cache
end

