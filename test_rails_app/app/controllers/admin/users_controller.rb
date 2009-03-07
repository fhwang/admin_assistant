class Admin::UsersController < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
  end
  
  protected
  
  # Run after a user is created
  def after_create(user)
    letters = 'abcdefghijklmnopqrstuvwxyz'.split //
    random_passwd = (1..10).to_a.map { letters[rand(letters.size)] }.join('')
    user.password = random_passwd
    user.save
  end
end
