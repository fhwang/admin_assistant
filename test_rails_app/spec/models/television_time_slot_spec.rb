require 'spec_helper'

describe TelevisionTimeSlot do
  before(:each) do
    @valid_attributes = {
      :time => Time.now
    }
  end

  it "should create a new instance given valid attributes" do
    TelevisionTimeSlot.create!(@valid_attributes)
  end
end
