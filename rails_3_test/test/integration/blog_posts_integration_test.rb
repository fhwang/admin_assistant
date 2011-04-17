$: << 'test'
require 'test_helper'

class BlogPostsIntegrationTest < ActionController::IntegrationTest
  def test_create_should_not_be_defined_by_admin_assistant
    assert_raise(AbstractController::ActionNotFound) do
      post "/blog_posts/create"
    end
  end
end
