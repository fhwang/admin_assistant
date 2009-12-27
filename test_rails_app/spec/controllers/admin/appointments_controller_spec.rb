require 'spec_helper'

describe Admin::AppointmentsController do
  integrate_views
  
  describe '#create with 2 new appointments' do
    before :each do
      Appointment.destroy_all
      post(
        :create,
        :appointment => {
          'a' => {
            'subject' => 'Lunch with Dick', 'time(1i)' => '2010',
            'time(2i)' => '1', 'time(3i)' => '4', 'time(4i)' => '12',
            'time(5i)' => '00'
          },
          'b' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          },
          'c' => {
            'subject' => 'Dinner with Jane', 'time(1i)' => '2010',
            'time(2i)' => '1', 'time(3i)' => '6', 'time(4i)' => '20',
            'time(5i)' => '00'
          },
          'd' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          },
          'e' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          },
          'f' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          },
          'g' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          },
          'h' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          },
          'i' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          },
          'j' => {
            'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
            'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
          }
        }
      )
      response.should_not be_error
    end
    
    it 'should create those two new appointments' do
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
    
    it 'should show prefixes in the subject field' do
      response.should have_tag('td', :text => /Prefix a/) do
        with_tag('input[name=?]', 'appointment[a][subject]')
      end
    end
    
    it 'should sensibly prefix the datetime fields' do
      response.should have_tag('select[name=?]', 'appointment[a][time(1i)]')
    end
  end
end
