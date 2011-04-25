class ApplicationController < ActionController::Base
  clear_helpers
  protect_from_forgery
  
  def self.do_something
  end
end
