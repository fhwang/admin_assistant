class Admin::Users2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
    a.index.search do |search|
      search.columns :blog_posts
      search[:blog_posts].match_text_fields_for_association
    end
  end
end
