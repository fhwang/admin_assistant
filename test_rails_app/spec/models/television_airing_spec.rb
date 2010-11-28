require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TelevisionAiring do
  before(:each) do
    @valid_attributes = {
      :television_time_slot_id => 1,
      :title => "value for title",
      :description => "value for description"
    }
  end

  it "should create a new instance given valid attributes" do
    TelevisionAiring.create!(@valid_attributes)
  end
end
