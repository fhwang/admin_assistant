class Admin::Images2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for Image do |a|
    a.index do |index|
      index.columns :image, :path, :created_at
    end
  end
end
