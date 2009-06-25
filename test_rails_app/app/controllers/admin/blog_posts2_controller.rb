class Admin::BlogPosts2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a[:user].label = 'Author'
    
    # When showing the textile field, say 'Yes' and 'No' instead of 'true'
    # and 'false'
    a[:textile].boolean_labels = %w(Yes No)
    
    # For the index view:
    a.index do |index|
      # Only show these columns
      index.columns :user, :title, :tags, :published_at, :textile
      
      # Add the link 'All' to the top-right corner
      index.actions['All'] = {:all => '1'}
      
      # Sort by published_at descending, then updated_at descending
      index.sort_by "published_at desc, updated_at desc"
      
      # Let's have specific fields for searching
      index.search :id, :title, :body, :textile, :user
      
      # Make the author field a link
      index[:user].link_to_args do |blog_post|
        { :controller => 'admin/users', :action => 'edit',
          :id => blog_post.user_id }
      end
    end
    
    # For any form page:
    a.form do |form|
      # Only show inputs for these fields
      form.columns :user, :title, :body, :tags, :textile, :publish
      
      # 'publish' isn't defined on BlogPost, we have to specify that it's a
      # check box
      form[:publish].input = :check_box
      
      # In addition to the 'Create'/'Update' button at the bottom, we also have
      # a 'Preview' button
      form.submit_buttons << 'Preview'
      
      form[:publish].description =
          "Click this and published_at will be set automatically"
        
      form[:user].select_options = {:include_blank => false}
    end
    
    # Only show some columns on the show page
    a.show.columns :user, :title, :body, :tags, :textile, :published_at
  end
  
  protected
  
  # This is run after all saves, whether they're creates or updates
  def after_save(blog_post)
    unless blog_post.tags.empty?
      blog_post.update_attribute(:tags_string, blog_post.tags.map(&:tag).join(','))
    end
  end
  
  # This is run before all saves, whether they're creates or updates
  def before_save(blog_post)
    if params[:blog_post][:publish] == '1' && blog_post.published_at.nil?
      blog_post.published_at = Time.now.utc
    end
  end
  
  # By default, only show unpublished blog posts unless params[:all] is
  # passed in
  def conditions_for_index
    "published_at is null" unless params[:all]
  end

  # After a successful save, redirect to the edit page with preview=1 to show
  # the preview pane. The HTML for the preview pane is generated in
  # app/views/admin/blog_posts2/_after_form.html.erb
  def destination_after_save(blog_post, params)
    if params[:commit] == 'Preview'
      {:action => 'edit', :id => blog_post.id, :preview => '1'}
    end
  end
  
  def extra_right_column_links_for_index(blog_post)
    [[
      'New comment',
      {
        :controller => 'admin/comments', :action => 'new',
        :comment => {:blog_post_id => blog_post.id}
      }
    ]]
  end
  
  # Preprocesses the 'tags' string from the form to an array of Tag objects.
  # That way admin_assistant can say
  #
  #   blog_post.tags = params[:tags]
  #
  # and this will work fine with the BlogPost#tags association
  def tags_from_form(tags_strings)
    tags_strings.split(/\s+/).map { |tag_str|
      Tag.find_by_tag(tag_str) || Tag.create(:tag => tag_str)
    }
  end
end
