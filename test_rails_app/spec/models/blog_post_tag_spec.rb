require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BlogPostTag do
  before(:each) do
    @valid_attributes = {
      :blog_post_id => 1,
      :tag_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    BlogPostTag.create!(@valid_attributes)
  end
end
