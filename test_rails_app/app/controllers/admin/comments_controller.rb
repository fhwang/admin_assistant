class Admin::CommentsController < ApplicationController
  layout 'admin'

  admin_assistant_for Comment do |a|
    a.form.read_only :comment
  end
end
