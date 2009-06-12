class Admin::BlogPosts3Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.model_class_name = 'post'
    
    a.index do |index|
      index.total_entries do
        25
      end
      
      # Add the link 'All' to the top-right corner
      index.actions['All'] = {:all => '1'}
      
      # By default, only show unpublished blog posts unless params[:all] is
      # passed in. This needs to work with or without use of the field search
      # feature
      index.conditions do |params|
        "published_at is null" unless params[:all]
      end
      
      # Extended search configuration
      index.search do |search|
        search.columns :id, :title, :body, :textile, :user
        search[:user].match_text_fields_for_association
      end
      
      # sort by user by default
      index.sort_by :user
    end
    
    a.form do |form|
      form.columns_for_new  :title, :user, :published_at
      form.columns_for_edit :title, :user, :published_at, :body
      form[:published_at].select_options = {:start_year => 2009}
    end
  end
end
