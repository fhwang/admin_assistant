class Admin::CommentsController < ApplicationController
  layout 'admin'

  admin_assistant_for Comment do |a|
    a.form[:comment].read_only
    
    a.index.conditions "comment like '%smart%'"
  end
end
