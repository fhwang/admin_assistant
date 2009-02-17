class Admin::BlogPostsController < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |admin|
  end
end
