class Admin::ImagesController < ApplicationController
  layout 'admin'

  admin_assistant_for Image do |a|
  end
end
