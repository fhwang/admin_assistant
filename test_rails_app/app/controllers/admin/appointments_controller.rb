class Admin::AppointmentsController < ApplicationController
  layout 'admin'

  admin_assistant_for Appointment do |a|
    a.form.multi = true
  end
end
