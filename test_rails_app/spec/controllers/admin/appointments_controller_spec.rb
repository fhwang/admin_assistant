require 'spec_helper'

describe Admin::AppointmentsController do
  integrate_views
  
  describe '#create with 2 new appointments' do
    before :all do
      User.destroy_all
      @user1 = User.create! :username => random_word
      @user2 = User.create! :username => random_word
    end
    
    before :each do
      Appointment.destroy_all
      post(
        :create,
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
      response.should_not be_error
    end
    
    it 'should create those two new appointments' do
      Appointment.count.should == 2
      Appointment.all.any? { |appt|
        appt.subject == 'Lunch with Dick' and
            appt.time == Time.utc(2010, 1, 4, 12, 0) and appt.user == @user1
      }.should be_true
      Appointment.all.any? { |appt|
        appt.subject == 'Dinner with Jane' and
            appt.time == Time.utc(2010, 1, 6, 20, 0) and appt.user == @user2
      }.should be_true
    end
  end
  
  describe '#create while missing a user_id' do
    before :each do
      post(
        :create,
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
      response.should_not be_error
    end

    it 'should show an error for user_id' do
      response.should be_success
      response.body.should match(/User can't be blank/)
    end
  end

  describe '#index' do
    before :all do
      user = User.first
      user || User.create!(:username => random_word)
      if Appointment.count == 0
        Appointment.create!(
          :subject => 'Lunch', :time => Time.utc(2010,2,18,13,0,0),
          :user => user
        )
      end
    end
    
    before :each do
      get :index
    end
  
    it 'should show a search range widget' do
      response.should have_tag('form#search_form') do
        %w(gt lt).each do |comparator|
          1.upto(5) do |num|
            name = "search[time][#{comparator}(#{num}i)]"
            with_tag('select[name=?]', name) do 
              with_tag "option[value='']"
            end
          end
        end
      end
    end
  end
  
  describe '#index when searching for an appointment after a specific time' do
    before :all do
      @user = User.first
      @user ||= User.create! :username => random_word
      @yesterday = 1.day.ago.to_date.to_time.utc
      @yesterdays_appt = Appointment.find_by_time @yesterday
      @yesterdays_appt ||= Appointment.create!(
        :subject => random_word, :user => @user, :time => @yesterday
      )
      @today = Time.now.to_date.to_time.utc
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
          'gt(1i)' => @today.year, 'gt(2i)' => @today.month,
          'gt(3i)' => @today.day, 'gt(4i)' => @today.hour, 'gt(5i)' => '00',
          'lt(1i)' => '', 'lt(2i)' => '', 'lt(3i)' => '', 'lt(4i)' => '',
          'lt(5i)' => ''
        }}
      )
      response.should be_success
    end
    
    it 'should prefill the search form fields' do
      response.should have_tag('form#search_form') do
        with_tag('select[name=?]', 'search[time][gt(1i)]') do
          with_tag('option[value=?][selected=selected]', @today.year)
        end
        with_tag('select[name=?]', 'search[time][gt(2i)]') do
          with_tag('option[value=?][selected=selected]', @today.month)
        end
        with_tag('select[name=?]', 'search[time][gt(3i)]') do
          with_tag('option[value=?][selected=selected]', @today.day)
        end
        with_tag('select[name=?]', 'search[time][gt(4i)]') do
          with_tag(
            'option[value=?][selected=selected]', sprintf('%02d', @today.hour)
          )
        end
        with_tag('select[name=?]', 'search[time][gt(5i)]') do
          with_tag('option[value=?][selected=selected]', '00')
        end
      end
    end
  
    it 'should not show an appointment before that time' do
      response.should_not have_tag('td', :text => @yesterdays_appt.subject)
    end
    
    it 'should not show an appointment equal to that time' do
      response.should_not have_tag('td', :text => @todays_appt.subject)
    end
    
    it 'should show an appointment after that time' do
      response.should have_tag('td', :text => @tomorrows_appt.subject)
    end
  end
  
  describe '#index when searching for an appointment before a specific time' do
    before :all do
      Appointment.destroy_all if Appointment.count > 20
      @user = User.first
      @user ||= User.create! :username => random_word
      @yesterday = 1.day.ago.to_date.to_time.utc
      @yesterdays_appt = Appointment.find_by_time @yesterday
      @yesterdays_appt ||= Appointment.create!(
        :subject => random_word, :user => @user, :time => @yesterday
      )
      @today = Time.now.to_date.to_time.utc
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
          'gt(1i)' => '', 'gt(2i)' => '', 'gt(3i)' => '', 'gt(4i)' => '',
          'gt(5i)' => '', 'lt(1i)' => @today.year, 'lt(2i)' => @today.month,
          'lt(3i)' => @today.day, 'lt(4i)' => @today.hour, 'lt(5i)' => '00'
        }}
      )
      response.should be_success
    end
    
    it 'should prefill the search form fields' do
      response.should have_tag('form#search_form') do
        with_tag('select[name=?]', 'search[time][lt(1i)]') do
          with_tag('option[value=?][selected=selected]', @today.year)
        end
        with_tag('select[name=?]', 'search[time][lt(2i)]') do
          with_tag('option[value=?][selected=selected]', @today.month)
        end
        with_tag('select[name=?]', 'search[time][lt(3i)]') do
          with_tag('option[value=?][selected=selected]', @today.day)
        end
        with_tag('select[name=?]', 'search[time][lt(4i)]') do
          with_tag(
            'option[value=?][selected=selected]', sprintf('%02d', @today.hour)
          )
        end
        with_tag('select[name=?]', 'search[time][lt(5i)]') do
          with_tag('option[value=?][selected=selected]', '00')
        end
      end
    end
    
    it 'should show an appointment before that time' do
      response.should have_tag('td', :text => @yesterdays_appt.subject)
    end
    
    it 'should not show an appointment equal to that time' do
      response.should_not have_tag('td', :text => @todays_appt.subject)
    end
    
    it 'should not show an appointment after that time' do
      response.should_not have_tag('td', :text => @tomorrows_appt.subject)
    end
  end
  
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
      @today = Time.now.to_date.to_time.utc
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
