class Admin::BlogPosts2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |admin|
    # for index pages:
    admin.index do |index|
      # only show some columns
      index.columns :title
    end
  end
end
