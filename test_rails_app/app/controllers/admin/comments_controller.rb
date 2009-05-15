class Admin::CommentsController < ApplicationController
  layout 'admin'

  admin_assistant_for Comment do |a|
    a.form[:comment].read_only
  end
end
