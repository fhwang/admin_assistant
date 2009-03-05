require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::AccountsController do
  integrate_views

  describe '#create' do
    before :each do
      post :create, :account => { :username => 'bill', :password => '' }
    end
    
    it 'should assign a new random password' do
      account = Account.find_by_username 'bill'
      account.should_not be_nil
      account.password.should_not == ''
    end
  end
  
  describe '#update' do
    before :all do
      @account = Account.create!(:username => 'betty', :password => 'crocker')
    end
    
    before :each do
      post :update, :id => @account.id, :account => {:username => 'bettie'}
    end
    
    it 'should not assign a new random password' do
      @account.reload
      @account.password.should == 'crocker'
    end
  end
end
