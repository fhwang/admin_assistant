$: << 'test'
require 'test_helper'

class BlogPostsIntegrationTest < ActionController::IntegrationTest
  def test_create_should_not_be_defined_by_admin_assistant
    post "/blog_posts/create"
    assert_response :not_found
  end
end
