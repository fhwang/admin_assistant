require 'spec_helper'

describe Admin::Appointments2Controller do
  integrate_views
  
  describe '#create with 2 new appointments' do
    before :each do
      Appointment.destroy_all
      post(
        :create,
        :appointment => {
          'a' => {
            'subject' => 'Lunch with Dick', 'time(1-3i)' => '2010-01-04',
            'time(4i)' => '12', 'time(5i)' => '00'
          },
          'b' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          },
          'c' => {
            'subject' => 'Dinner with Jane', 'time(1-3i)' => '2010-01-06',
            'time(4i)' => '20', 'time(5i)' => '00'
          },
          'd' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          },
          'e' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          },
          'f' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          },
          'g' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          },
          'h' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          },
          'i' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          },
          'j' => {
            'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
            'time(5i)' => ''
          }
        }
      )
    end
    
    it 'should save 2 new appointments with the correct times' do
      Appointment.count.should == 2
      Appointment.all.any? { |appt|
        appt.subject == 'Lunch with Dick' and
            appt.time == Time.utc(2010, 1, 4, 12, 0)
      }.should be_true
      Appointment.all.any? { |appt|
        appt.subject == 'Dinner with Jane' and
            appt.time == Time.utc(2010, 1, 6, 20, 0)
      }.should be_true
    end
  end

  describe '#new' do
    before :each do
      get :new
    end
    
    it 'should use _time_input.html.erb to show a custom time widget' do
      response.should have_tag(
        'select[name=?]', 'appointment[a][time(1-3i)]'
      ) do
        with_tag "option[value=?]", "2010-01-04", :text => 'Mon Jan 04 2010'
      end
    end
  end
end
