class Admin::TelevisionTimeSlotsController < ApplicationController
  layout 'admin'

  admin_assistant_for TelevisionTimeSlot
end
