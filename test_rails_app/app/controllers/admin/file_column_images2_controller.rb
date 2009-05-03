class Admin::FileColumnImages2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for FileColumnImage do |a|
    a.index.columns :image
  end
end
