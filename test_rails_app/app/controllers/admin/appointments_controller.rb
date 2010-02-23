class Admin::AppointmentsController < ApplicationController
  layout 'admin'

  admin_assistant_for Appointment do |a|
    a.form.multi = true
    a.index.search do |search|
      search.columns :subject, :time, :user
      search[:time].compare_to_range = true
    end
  end
end
