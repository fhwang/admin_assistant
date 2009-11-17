class Admin::CommentsController < ApplicationController
  layout 'admin'

  admin_assistant_for Comment do |a|
    a.form[:comment].read_only
    
    a.index do |index|
      index.conditions "comment like '%smart%'"
      index.search.default_search_matches_on << :id
    end
  end
end
