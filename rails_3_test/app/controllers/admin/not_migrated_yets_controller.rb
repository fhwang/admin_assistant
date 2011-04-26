class Admin::NotMigratedYetsController < ApplicationController
  layout 'admin'

  admin_assistant_for NotMigratedYet do |a|
    a.index do |index|
      index.columns :id, :created_at, :updated_at
    end
  end
end
