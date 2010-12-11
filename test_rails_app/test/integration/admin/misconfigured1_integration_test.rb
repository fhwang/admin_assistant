require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::Misconfigured1IntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren', :password => 'password'
  end
  
  def test_index
    # should raise an explanatory error
    get "/admin/misconfigured1"
    assert_match(
      /Virtual search column :has_something needs a conditions block/,
      response.body
    )
  end
end
