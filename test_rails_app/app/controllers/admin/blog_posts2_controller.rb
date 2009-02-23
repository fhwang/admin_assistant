class Admin::BlogPosts2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.index do |index|
      index.columns :title, :tags, :published_at
      index.actions['All'] = {:all => '1'}
      index.conditions do |params|
        "published_at is null" unless params[:all]
      end
    end
    a.form do |form|
      form.columns :title, :body, :tags, :textile, :publish
      form.inputs[:publish] = :check_box
      form.submit_buttons << 'Preview'
    end
    a.tags_for_save do |tags_from_form|
      tags_from_form.split(/\s+/).map { |tag_str|
        Tag.find_by_tag(tag_str) || Tag.create(:tag => tag_str)
      }
    end
    a.before_save do |blog_post, params|
      if params[:blog_post][:publish] == '1' && blog_post.published_at.nil?
        blog_post.published_at = Time.now.utc
      end
    end
    a.destination_after_save do |blog_post, params|
      if params[:commit] == 'Preview'
        {:action => 'edit', :id => blog_post.id, :preview => '1'}
      end
    end
  end
end
