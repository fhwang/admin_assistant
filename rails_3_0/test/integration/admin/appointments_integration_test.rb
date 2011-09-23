require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::AppointmentsIntegrationTest < ActionController::IntegrationTest
  def test_create_with_2_new_appointments
    User.destroy_all
    @user1 = User.create! :username => random_word
    @user2 = User.create! :username => random_word
    Appointment.destroy_all
    post(
      "/admin/appointments",
      :appointment => {
        'a' => {
          'subject' => 'Lunch with Dick', 'time(1i)' => '2010',
          'time(2i)' => '1', 'time(3i)' => '4', 'time(4i)' => '12',
          'time(5i)' => '00', 'user_id' => @user1.id
        },
        'b' => {
          'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
          'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
        },
        'c' => {
          'subject' => 'Dinner with Jane', 'time(1i)' => '2010',
          'time(2i)' => '1', 'time(3i)' => '6', 'time(4i)' => '20',
          'time(5i)' => '00', 'user_id' => @user2.id
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
    assert_response :redirect
    # should create those two new appointments
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
  
  def test_create_while_missing_a_user_id
    post(
      "/admin/appointments",
      :appointment => {
        'a' => {
          'subject' => 'Lunch with Dick', 'time(1i)' => '2010',
          'time(2i)' => '1', 'time(3i)' => '4', 'time(4i)' => '12',
          'time(5i)' => '00', 'user_id' => ''
        },
        'b' => {
          'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
          'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
        },
        'c' => {
          'subject' => '', 'time(1i)' => '', 'time(2i)' => '',
          'time(3i)' => '', 'time(4i)' => '', 'time(5i)' => ''
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
    # should show an error for user_id
    assert_response :success
    assert_match(/User can't be blank/, response.body)
  end
  
  def test_index
    user = User.first
    user ||= User.create!(:username => random_word)
    if Appointment.count == 0
      Appointment.create!(
        :subject => 'Lunch', :time => Time.utc(2010,2,18,13,0,0),
        :user => user
      )
    end
    get "/admin/appointments"
    # should show a search range widget
    assert_select('form#search_form') do
      %w(gt lt).each do |comparator|
        1.upto(5) do |num|
          name = "search[time][#{comparator}(#{num}i)]"
          assert_select('select[name=?]', name) do 
            assert_select "option[value='']"
          end
        end
      end
    end
  end
  
  def test_index_when_searching_for_an_appt_after_a_specific_time
    @user = User.first
    @user ||= User.create! :username => random_word
    @yesterday = 1.day.ago.to_date.to_time.utc
    @yesterdays_appt = Appointment.where(:time => @yesterday)
    @yesterdays_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @yesterday
    )
    @today = Time.now.to_date.to_time.utc
    @todays_appt = Appointment.where(:time => @today)
    @todays_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @today
    )
    @tomorrow = 1.day.from_now.to_date.to_time.utc
    @tomorrows_appt = Appointment.where(:time => @tomorrow)
    @tomorrows_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @tomorrow
    )
    get(
      "/admin/appointments",
      :search => {:time => {
        'gt(1i)' => @today.year, 'gt(2i)' => @today.month,
        'gt(3i)' => @today.day, 'gt(4i)' => @today.hour, 'gt(5i)' => '00',
        'lt(1i)' => '', 'lt(2i)' => '', 'lt(3i)' => '', 'lt(4i)' => '',
        'lt(5i)' => ''
      }}
    )
    assert_response :success
    
    # should prefill the search form fields
    assert_select('form#search_form') do
      assert_select('select[name=?]', 'search[time][gt(1i)]') do
        assert_select('option[value=?][selected=selected]', @today.year)
      end
      assert_select('select[name=?]', 'search[time][gt(2i)]') do
        assert_select('option[value=?][selected=selected]', @today.month)
      end
      assert_select('select[name=?]', 'search[time][gt(3i)]') do
        assert_select('option[value=?][selected=selected]', @today.day)
      end
      assert_select('select[name=?]', 'search[time][gt(4i)]') do
        assert_select(
          'option[value=?][selected=selected]', sprintf('%02d', @today.hour)
        )
      end
      assert_select('select[name=?]', 'search[time][gt(5i)]') do
        assert_select('option[value=?][selected=selected]', '00')
      end
    end
    
    # should not show an appointment before that time
    assert_no_match(/#{@yesterdays_appt.subject}/, response.body)
    
    # should not show an appointment equal to that time
    assert_no_match(/#{@todays_appt.subject}/, response.body)
    
    # should show an appointment after that time
    assert_select('td', :text => @tomorrows_appt.subject)
  end
  
  def test_index_when_searching_for_an_appointment_before_a_specific_time
    Appointment.destroy_all if Appointment.count > 20
    @user = User.first
    @user ||= User.create! :username => random_word
    @yesterday = 1.day.ago.to_date.to_time.utc
    @yesterdays_appt = Appointment.where(:time => @yesterday)
    @yesterdays_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @yesterday
    )
    @today = 0.minutes.ago.to_date.to_time.utc
    @todays_appt = Appointment.where(:time => @today)
    @todays_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @today
    )
    @tomorrow = 1.day.from_now.to_date.to_time.utc
    @tomorrows_appt = Appointment.where(:time => @tomorrow)
    @tomorrows_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @tomorrow
    )
    get(
      "/admin/appointments",
      :search => {:time => {
        'gt(1i)' => '', 'gt(2i)' => '', 'gt(3i)' => '', 'gt(4i)' => '',
        'gt(5i)' => '', 'lt(1i)' => @today.year, 'lt(2i)' => @today.month,
        'lt(3i)' => @today.day, 'lt(4i)' => @today.hour, 'lt(5i)' => '00'
      }}
    )
    assert_response :success
    
    # should prefill the search form fields
    assert_select('form#search_form') do
      assert_select('select[name=?]', 'search[time][lt(1i)]') do
        assert_select('option[value=?][selected=selected]', @today.year)
      end
      assert_select('select[name=?]', 'search[time][lt(2i)]') do
        assert_select('option[value=?][selected=selected]', @today.month)
      end
      assert_select('select[name=?]', 'search[time][lt(3i)]') do
        assert_select('option[value=?][selected=selected]', @today.day)
      end
      assert_select('select[name=?]', 'search[time][lt(4i)]') do
        assert_select(
          'option[value=?][selected=selected]', sprintf('%02d', @today.hour)
        )
      end
      assert_select('select[name=?]', 'search[time][lt(5i)]') do
        assert_select('option[value=?][selected=selected]', '00')
      end
    end
    
    # should show an appointment before that time
    assert_select('td', :text => @yesterdays_appt.subject)
    
    # should not show an appointment equal to that time
    assert_no_match(/#{@todays_appt.subject}/, response.body)
    
    # should not show an appointment after that time
    assert_no_match(/#{@tomorrows_appt.subject}/, response.body)
  end
  
  def test_index_when_searching_for_an_appointment_within_a_time_range
    Appointment.destroy_all if Appointment.count > 20
    @user = User.first
    @user ||= User.create! :username => random_word
    @yesterday = 1.day.ago.to_date.to_time.utc
    @yesterdays_appt = Appointment.where(:time => @yesterday)
    @yesterdays_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @yesterday
    )
    @today = 0.minutes.ago.to_date.to_time.utc
    @todays_appt = Appointment.where(:time => @today)
    @todays_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @today
    )
    @tomorrow = 1.day.from_now.to_date.to_time.utc
    @tomorrows_appt = Appointment.where(:time => @tomorrow)
    @tomorrows_appt ||= Appointment.create!(
      :subject => random_word, :user => @user, :time => @tomorrow
    )
    get(
      "/admin/appointments",
      :search => {:time => {
        'gt(1i)' => @yesterday.year, 'gt(2i)' => @yesterday.month,
        'gt(3i)' => @yesterday.day, 'gt(4i)' => @yesterday.hour,
        'gt(5i)' => '', 'lt(1i)' => @tomorrow.year,
        'lt(2i)' => @tomorrow.month, 'lt(3i)' => @tomorrow.day,
        'lt(4i)' => @tomorrow.hour, 'lt(5i)' => '00'
      }}
    )
    assert_response :success
    
    # should prefill the search form fields
    assert_select('form#search_form') do
      assert_select('select[name=?]', 'search[time][gt(1i)]') do
        assert_select('option[value=?][selected=selected]', @yesterday.year)
      end
      assert_select('select[name=?]', 'search[time][gt(2i)]') do
        assert_select('option[value=?][selected=selected]', @yesterday.month)
      end
      assert_select('select[name=?]', 'search[time][gt(3i)]') do
        assert_select('option[value=?][selected=selected]', @yesterday.day)
      end
      assert_select('select[name=?]', 'search[time][gt(4i)]') do
        assert_select(
          'option[value=?][selected=selected]',
          sprintf('%02d', @yesterday.hour)
        )
      end
      assert_select('select[name=?]', 'search[time][gt(5i)]') do
        assert_select('option[value=?][selected=selected]', '00')
      end
      assert_select('select[name=?]', 'search[time][lt(1i)]') do
        assert_select('option[value=?][selected=selected]', @tomorrow.year)
      end
      assert_select('select[name=?]', 'search[time][lt(2i)]') do
        assert_select('option[value=?][selected=selected]', @tomorrow.month)
      end
      assert_select('select[name=?]', 'search[time][lt(3i)]') do
        assert_select('option[value=?][selected=selected]', @tomorrow.day)
      end
      assert_select('select[name=?]', 'search[time][lt(4i)]') do
        assert_select(
          'option[value=?][selected=selected]',
          sprintf('%02d', @tomorrow.hour)
        )
      end
      assert_select('select[name=?]', 'search[time][lt(5i)]') do
        assert_select('option[value=?][selected=selected]', '00')
      end
    end
    
    # should not show an appointment before that range
    assert_no_match(/#{@yesterdays_appt.subject}/, response.body)
    
    # should show an appointment in that range
    assert_select('td', :text => @todays_appt.subject)
    
    # should not show an appointment after that range
    assert_no_match(/#{@tomorrows_appt.subject}/, response.body)
  end

  def test_new
    User.destroy_all
    @user = User.create! :username => random_word
    get "/admin/appointments/new"
    
    # should show prefixes in the subject field
    assert_select('td', :text => /Prefix a/) do
      assert_select('input[name=?]', 'appointment[a][subject]')
    end
    
    # should sensibly prefix the datetime fields
    assert_select('select[name=?]', 'appointment[a][time(1i)]')
    
    # should include a user selector
    assert_select('select[name=?]', 'appointment[a][user_id]') do
      assert_select 'option[value=?]', @user.id, :text => /#{@user.username}/
    end
  end
end
