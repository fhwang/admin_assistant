require 'spec_helper'

describe Admin::AppointmentsController do
  integrate_views

  describe '#new' do
    before :each do
      get :new
    end
    
    it 'should show prefixes in the subject field' do
      response.should have_tag('td', :text => /Prefix a/) do
        with_tag('input[name=?]', 'appointment[a][subject]')
      end
    end
  end
end
