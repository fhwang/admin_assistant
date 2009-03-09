class Admin::CommentsController < ApplicationController
  layout 'admin'

  admin_assistant_for Comment do |a|
    a.form do |form|
      form.read_only :comment
    end
  end
end
