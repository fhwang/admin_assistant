class Admin::FileColumnImagesController < ApplicationController
  layout 'admin'

  admin_assistant_for FileColumnImage do |a|
  end
end
