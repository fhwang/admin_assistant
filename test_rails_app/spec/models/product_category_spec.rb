=begin
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ProductCategory do
  before(:each) do
    @valid_attributes = {
      :category_name => "value for category_name", :position => 1
    }
  end

  it "should create a new instance given valid attributes" do
    ProductCategory.create!(@valid_attributes)
  end
end
=end
