require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::Appointments2IntegrationTest < ActionController::IntegrationTest
  def test_create_with_2_new_appointments
    User.destroy_all
    @user1 = User.create! :username => random_word
    @user2 = User.create! :username => random_word
    Appointment.destroy_all
    post(
      "/admin/appointments2/create",
      :appointment => {
        'a' => {
          'subject' => 'Lunch with Dick', 'time(1-3i)' => '2010-01-04',
          'time(4i)' => '12', 'time(5i)' => '00', 'user_id' => @user1.id
        },
        'b' => {
          'subject' => '', 'time(1-3i)' => '', 'time(4i)' => '',
          'time(5i)' => ''
        },
        'c' => {
          'subject' => 'Dinner with Jane', 'time(1-3i)' => '2010-01-06',
          'time(4i)' => '20', 'time(5i)' => '00', 'user_id' => @user2.id
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
    # should save 2 new appointments with the correct times
    assert_equal(2, Appointment.count)
    assert(
      Appointment.all.any? { |appt|
        appt.subject == 'Lunch with Dick' and
          appt.time == Time.utc(2010, 1, 4, 12, 0) and appt.user == @user1
      }
    )
    assert(
      Appointment.all.any? { |appt|
        appt.subject == 'Dinner with Jane' and
          appt.time == Time.utc(2010, 1, 6, 20, 0) and appt.user == @user2
      }
    )
  end
  
  def test_new
    get "/admin/appointments2/new"
    # should use _time_input.html.erb to show a custom time widget
    assert_select('select[name=?]', 'appointment[a][time(1-3i)]') do
      assert_select(
        "option[value=?]", "2010-01-04", :text => 'Mon Jan 04 2010'
      )
    end
  end
end
