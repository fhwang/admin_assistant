class Admin::BlogPosts4Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a[:published_at].strftime_format = "%b %d, %Y %H:%M:%S"
    
    a.index do |index|
      index.columns :user, :title, :tags, :published_at, :textile
      index.search :id, :title, :body, :textile, :user, :published_at
      
      index.total_entries do
        25
      end
    end
    
    a.form do |form|
      form.columns :title, :body, :textile, :published_at, :user, :virtual_text
      form[:virtual_text].input = :text_area
    end
  end
end
