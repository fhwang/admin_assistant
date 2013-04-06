class Admin::Misconfigured1Controller < ApplicationController
  admin_assistant_for BlogPost do |a|
    a.index.search do |search|
      search.columns :has_something
    end
  end
end
