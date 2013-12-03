class Admin::Users2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
    a.index.include :address
    a.index.search do |search|
      search.columns :blog_posts, :street
      search[:street].conditions do |street|
        "addresses.street like '%#{street}%'" if street
      end
      search[:blog_posts].match_text_fields_for_association
    end
  end
end
