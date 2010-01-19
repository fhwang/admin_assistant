class Admin::BlogPosts5Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.index do |index|
      index.conditions do |params|
        "user_id = #{params[:filter]}" unless params[:filter].blank?
      end
      
      index.columns :user, :title, :tags, :published_at, :textile
    end
    
    a.form.columns :user, :title, :title_alt
  end
  
  protected
  
  def title_from_form(title_str, record_params)
    if title_str.blank?
      record_params[:title_alt]
    else
      title_str
    end
  end
end
