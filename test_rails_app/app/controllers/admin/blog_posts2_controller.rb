class Admin::BlogPosts2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.label :user, 'Author'
    
    # For the index view:
    a.index do |index|
      # Only show these columns
      index.columns :user, :title, :tags, :published_at, :textile
      
      # Add the link 'All' to the top-right corner
      index.actions['All'] = {:all => '1'}
      
      # By default, only show unpublished blog posts unless params[:all] is
      # passed in
      index.conditions do |params|
        "published_at is null" unless params[:all]
      end
      
      # Sort by published_at descending, then updated_at descending
      index.sort_by "published_at desc, updated_at desc"
      
      # When showing the textile field, say 'Yes' and 'No' instead of 'true'
      # and 'false'
      index.boolean_labels :textile => %w(Yes No)
    end
    
    # For any form page:
    a.form do |form|
      # Only show inputs for these fields
      form.columns :user, :title, :body, :tags, :textile, :publish
      
      # 'publish' isn't defined on BlogPost, we have to specify that it's a
      # check box
      form.inputs[:publish] = :check_box
      
      # In addition to the 'Create'/'Update' button at the bottom, we also have
      # a 'Preview' button
      form.submit_buttons << 'Preview'
    end
  end
  
  protected
  
  # This is run before all saves, whether they're creates or updates
  def before_save(blog_post)
    if params[:blog_post][:publish] == '1' && blog_post.published_at.nil?
      blog_post.published_at = Time.now.utc
    end
  end

  # After a successful save, redirect to the edit page with preview=1 to show
  # the preview pane. The HTML for the preview pane is generated in
  # app/views/admin/blog_posts2/_after_form.html.erb
  def destination_after_save(blog_post, params)
    if params[:commit] == 'Preview'
      {:action => 'edit', :id => blog_post.id, :preview => '1'}
    end
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
