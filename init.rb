require 'admin_assistant'

class ::ApplicationController < ActionController::Base
  include AdminAssistant::ControllerMethods
end
