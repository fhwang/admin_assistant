class Admin::BlogPosts3Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.index do |index|
      index.total_entries = lambda { 25 }
    end
  end
end
