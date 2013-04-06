require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::Misconfigured1IntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren', :password => 'password'
  end
  
  def test_index
    # should raise an explanatory error
    begin
      get "/admin/misconfigured1"
      fail "raise expected"
    rescue ActionView::Template::Error
      assert_match(
        /Virtual search column :has_something needs a conditions block/,
        $!.message
      )
    end
  end
end
