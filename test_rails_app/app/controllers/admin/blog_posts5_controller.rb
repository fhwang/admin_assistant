class Admin::BlogPosts5Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.index do |index|
      index.conditions do |params|
        "user_id = #{params[:filter]}" unless params[:filter].blank?
      end
      
      index.columns :user, :title, :tags, :published_at, :textile
    end
  end
end
