class Admin::AccountsController < ApplicationController
  layout 'admin'

  admin_assistant_for Account do |a|
  end
  
  protected
  
  # Run after an account is created
  def after_create(account)
    letters = 'abcdefghijklmnopqrstuvwxyz'.split //
    random_passwd = (1..10).to_a.map { letters[rand(letters.size)] }.join('')
    account.password = random_passwd
    account.save
  end
end
