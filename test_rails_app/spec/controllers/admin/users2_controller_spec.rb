require 'spec_helper'

describe Admin::Users2Controller do
  integrate_views
  
  describe '#index' do
    before :all do
      User.create!(:username => random_word) if User.count == 0
    end
    
    before :each do
      get :index
    end
  
    it 'should show the empty search form' do
      response.should have_tag('form#search_form') do
        with_tag('input[name=?]', 'search[blog_posts]')
      end
    end
  end
  
  describe '#index when searching by blog post' do
    before :all do
      User.destroy_all
      @soren = User.create! :username => 'soren'
      @jean_paul = User.create! :username => 'jean_paul'
      BlogPost.create!(
        :user => @jean_paul, :title => 'No Foobar',
        :body => 'Hell is other foobars'
      )
      @friedrich = User.create! :username => 'friedrich'
      BlogPost.create!(
        :user => @friedrich, :title => 'Thus Spake Zarafoobar',
        :body => 'Man is something that shall be overfoobared.'
      )
      BlogPost.create!(
        :user => @friedrich, :title => 'Beyond Good and Foobar',
        :body =>
          'And when you gaze long into a foobar the foobar also gazes into you.'
      )
    end
  
    before :each do
      get :index, :search => {:blog_posts => 'foobar'}
    end
  
    it 'should prefill the search form fields' do
      response.should have_tag('form#search_form') do
        with_tag('input[name=?][value=?]', 'search[blog_posts]', 'foobar')
      end
    end
    
    it 'should not match a user without any matching blog posts' do
      response.should_not have_tag('td', :text => @soren.username)
    end
    
    it 'should match a user with one matching blog post' do
      response.should have_tag('td', :text => @jean_paul.username)
    end
    
    it 'should match a user with two matching blog posts, only presenting that user once' do
      response.should have_tag('td', :text => @friedrich.username, :count => 1)
    end
  end
end
