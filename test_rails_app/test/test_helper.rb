ENV["RAILS_ENV"] = "test"
here = File.dirname(__FILE__)
require File.expand_path(here + "/../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + "/../spec/spec_or_test_helper")

if %w(2.1.0 2.1.2).include?(RAILS_GEM_VERSION)
  class Test::Unit::TestCase
    self.use_transactional_fixtures = true
  
    self.use_instantiated_fixtures  = false
  
    include SpecOrTestHelper
  end
else
  class ActiveSupport::TestCase
    self.use_transactional_fixtures = true
  
    self.use_instantiated_fixtures  = false
    
    include SpecOrTestHelper
  end
end

Webrat.configure do |config|  
  config.mode = :rails  
end  

