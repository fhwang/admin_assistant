ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  def random_word( length = 25 )
    letters = 'abcdefghijklmnopqrstuvwxyz_'.split //
    ( 1..length ).to_a.map { letters[rand(letters.size)] }.join( '' )
  end
end
