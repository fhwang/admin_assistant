class Admin::BookmarksController < ApplicationController
  layout 'admin'

  admin_assistant_for Bookmark do |a|
    a[:bookmarkable].polymorphic_types = [BlogPost, Comment, Product, User]    

    a.index.search :user, :bookmarkable
    
    a.form[:user].select_options = {:include_blank => false}
  end
end
