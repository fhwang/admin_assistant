require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::AppointmentsController do
  integrate_views
  
  describe '#index when searching for an appointment within a time range' do
    before :all do
      Appointment.destroy_all if Appointment.count > 20
      @user = User.first
      @user ||= User.create! :username => random_word
      @yesterday = 1.day.ago.to_date.to_time.utc
      @yesterdays_appt = Appointment.find_by_time @yesterday
      @yesterdays_appt ||= Appointment.create!(
        :subject => random_word, :user => @user, :time => @yesterday
      )
      @today = 0.minutes.ago.to_date.to_time.utc
      @todays_appt = Appointment.find_by_time @today
      @todays_appt ||= Appointment.create!(
        :subject => random_word, :user => @user, :time => @today
      )
      @tomorrow = 1.day.from_now.to_date.to_time.utc
      @tomorrows_appt = Appointment.find_by_time @tomorrow
      @tomorrows_appt ||= Appointment.create!(
        :subject => random_word, :user => @user, :time => @tomorrow
      )
    end
    
    before :each do
      get(
        :index,
        :search => {:time => {
          'gt(1i)' => @yesterday.year, 'gt(2i)' => @yesterday.month,
          'gt(3i)' => @yesterday.day, 'gt(4i)' => @yesterday.hour,
          'gt(5i)' => '', 'lt(1i)' => @tomorrow.year,
          'lt(2i)' => @tomorrow.month, 'lt(3i)' => @tomorrow.day,
          'lt(4i)' => @tomorrow.hour, 'lt(5i)' => '00'
        }}
      )
      response.should be_success
    end
    
    it 'should prefill the search form fields' do
      response.should have_tag('form#search_form') do
        with_tag('select[name=?]', 'search[time][gt(1i)]') do
          with_tag('option[value=?][selected=selected]', @yesterday.year)
        end
        with_tag('select[name=?]', 'search[time][gt(2i)]') do
          with_tag('option[value=?][selected=selected]', @yesterday.month)
        end
        with_tag('select[name=?]', 'search[time][gt(3i)]') do
          with_tag('option[value=?][selected=selected]', @yesterday.day)
        end
        with_tag('select[name=?]', 'search[time][gt(4i)]') do
          with_tag(
            'option[value=?][selected=selected]',
            sprintf('%02d', @yesterday.hour)
          )
        end
        with_tag('select[name=?]', 'search[time][gt(5i)]') do
          with_tag('option[value=?][selected=selected]', '00')
        end
        with_tag('select[name=?]', 'search[time][lt(1i)]') do
          with_tag('option[value=?][selected=selected]', @tomorrow.year)
        end
        with_tag('select[name=?]', 'search[time][lt(2i)]') do
          with_tag('option[value=?][selected=selected]', @tomorrow.month)
        end
        with_tag('select[name=?]', 'search[time][lt(3i)]') do
          with_tag('option[value=?][selected=selected]', @tomorrow.day)
        end
        with_tag('select[name=?]', 'search[time][lt(4i)]') do
          with_tag(
            'option[value=?][selected=selected]',
            sprintf('%02d', @tomorrow.hour)
          )
        end
        with_tag('select[name=?]', 'search[time][lt(5i)]') do
          with_tag('option[value=?][selected=selected]', '00')
        end
      end
    end
    
    it 'should not show an appointment before that range' do
      response.should_not have_tag('td', :text => @yesterdays_appt.subject)
    end
    
    it 'should show an appointment in that range' do
      response.should have_tag('td', :text => @todays_appt.subject)
    end
    
    it 'should not show an appointment after that range' do
      response.should_not have_tag('td', :text => @tomorrows_appt.subject)
    end
  end

  describe '#new' do
    before :all do
      User.destroy_all
      @user = User.create! :username => random_word
    end
    
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
    
    it 'should include a user selector' do
      response.should have_tag('select[name=?]', 'appointment[a][user_id]') do
        with_tag 'option[value=?]', @user.id, :text => /#{@user.username}/
      end
    end
  end
end
