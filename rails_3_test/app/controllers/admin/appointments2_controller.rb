class Admin::Appointments2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for Appointment do |a|
    a.form.multi = true
  end
  
  protected
  
  def time_from_form(time)
    time['1-3i'] =~ /(\d{4})-(\d{2})-(\d{2})/
    utc_args = [$1, $2, $3, time['4i'], time['5i']]
    Time.utc(*(utc_args.map(&:to_i))) unless utc_args.any?(&:blank?)
  end
end
