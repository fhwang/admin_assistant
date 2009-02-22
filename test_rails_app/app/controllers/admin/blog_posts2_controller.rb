class Admin::BlogPosts2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.index do |index|
      index.columns :title, :tags
    end
    a.form do |form|
      form.columns :title, :body, :tags
    end
  end
end
