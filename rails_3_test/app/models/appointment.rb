class Appointment < ActiveRecord::Base
  validates_presence_of :subject, :time, :user_id
  
  belongs_to :user
end
