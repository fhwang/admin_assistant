class Admin::BlogPostsCustomNewAndEditController < ApplicationController
  layout 'admin'
  
  admin_assistant_for BlogPost do |a|
    a.actions :index, :show, :destroy
  end
  
  def new
    render :text => 'custom form for new'
  end
  
  def edit
    render :text => 'custom form for edit'
  end
end
