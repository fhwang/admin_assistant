class Appointment < ActiveRecord::Base
  validates_presence_of :subject, :time
end
