class TelevisionTimeSlot < ActiveRecord::Base
  validates_presence_of :time

  def name_for_admin_assistant
    time.strftime("%a %b %d %I:%M %p")
  end
  
  def sort_value_for_admin_assistant
    time
  end
end
