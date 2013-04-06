require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::TelevisionAiringsIntegrationTest < 
      ActionController::IntegrationTest
  def test_new
    TelevisionTimeSlot.destroy_all
    @tv_time_slot1 = TelevisionTimeSlot.create!(
      :time => Time.utc(2010, 2, 14, 9)
    )
    @tv_time_slot2 = TelevisionTimeSlot.create!(
      :time => Time.utc(2010, 2, 14, 14)
    )
    get "/admin/television_airings/new"
    assert_response :success
    
    # should sort television time slots by time, not by the time string
    assert_select(
      'select[name=?]', 'television_airing[television_time_slot_id]'
    ) do
      assert_select 'option:first-child[value=""]'
      assert_select 'option:nth-child(2)[value=?]', @tv_time_slot1.id
      assert_select 'option:nth-child(3)[value=?]', @tv_time_slot2.id
    end
  end
end
