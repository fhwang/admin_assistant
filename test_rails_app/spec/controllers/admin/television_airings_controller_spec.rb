require 'spec_helper'

describe Admin::TelevisionAiringsController do
  integrate_views
  
  describe '#new' do
    before :all do
      TelevisionTimeSlot.destroy_all
      @tv_time_slot1 = TelevisionTimeSlot.create!(
        :time => Time.utc(2010, 2, 14, 9)
      )
      @tv_time_slot2 = TelevisionTimeSlot.create!(
        :time => Time.utc(2010, 2, 14, 14)
      )
    end
    
    before :each do
      get :new
      response.should be_success
    end
    
    it 'should sort television time slots by time, not by the time string' do
      response.should have_tag(
        'select[name=?]', 'television_airing[television_time_slot_id]'
      ) do
        with_tag 'option:first-child[value=""]'
        with_tag 'option:nth-child(2)[value=?]', @tv_time_slot1.id
        with_tag 'option:nth-child(3)[value=?]', @tv_time_slot2.id
      end
    end
  end
end
