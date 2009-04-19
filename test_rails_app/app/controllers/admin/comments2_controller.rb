class Admin::Comments2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for Comment do |a|
    a.form do |form|
      form.write_once :comment
    end
  end
end
