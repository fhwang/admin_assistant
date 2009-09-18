class Admin::BlogPosts4Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.index do |index|
      index.columns :user, :title, :tags, :published_at, :textile
      
      index.search :id, :title, :body, :textile, :user, :published_at
    end
  end
end
