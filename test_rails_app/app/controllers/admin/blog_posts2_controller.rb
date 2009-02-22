class Admin::BlogPosts2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.index do |index|
      index.columns :title, :tags
    end
    a.form do |form|
      form.columns :title, :body, :tags
    end
    a.tags_for_save do |tags_from_form|
      tags_from_form.split(/\s+/).map { |tag_str|
        Tag.find_by_tag(tag_str) || Tag.create(:tag => tag_str)
      }
    end
  end
end
