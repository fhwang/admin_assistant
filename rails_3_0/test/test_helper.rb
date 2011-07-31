ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
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
  
  def random_word( length = 25 )
    letters = 'abcdefghijklmnopqrstuvwxyz_'.split //
    ( 1..length ).to_a.map { letters[rand(letters.size)] }.join( '' )
  end
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

include Webrat::Methods 
include Webrat::Matchers

Webrat.configure do |config|  
  config.mode = :rails  
end

class ActionController::IntegrationTest
  
  # Rails 3.0 renders link hrefs like:
  #   /admin/comments/new?comment[blog_post_id]=1
  # Rails 3.1 renders link hrefs like:
  #   /admin/comments/new?comment%5Bblog_post_id%5D=1
  
  unless method_defined?(
      :assert_select_with_preprocessed_hrefs_across_rails_versions
  )
    def assert_select_with_preprocessed_hrefs_across_rails_versions(*args)
      old_args = args
      args = []
      args.unshift(old_args.shift)
      until old_args.empty?
        next_arg = old_args.shift
        if next_arg.is_a?(String) && Rails.version =~ /^3.1/
          next_arg.gsub!(/(\?\w+)\[/, '\1%5B')
          next_arg.gsub!(/(\?\w+%5B\w+)\]/, '\1%5D')
        end
        args.push next_arg
      end
      assert_select_without_preprocessed_hrefs_across_rails_versions(*args)
    end
  
    alias_method_chain :assert_select,
                       :preprocessed_hrefs_across_rails_versions
  end
  
  def assert_will_paginate_link(base, page, content = nil)
    select = []
    if Rails.version =~ /^3.1/
      select << "a[href=#{base}?escape=false&amp;page=#{page}]"
    else
      select << "a[href=#{base}?page=#{page}]"
    end
    select << content if content
    assert_select(select)
  end
end
