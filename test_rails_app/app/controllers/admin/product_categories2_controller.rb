class Admin::ProductCategories2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for ProductCategory do |a|
    a.form.multi = true
  end
end
