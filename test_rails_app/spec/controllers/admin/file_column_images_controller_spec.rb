require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::FileColumnImagesController do
  integrate_views
  
  describe '#index' do
    before :all do
      @file_column_image = FileColumnImage.create!(
        :image => File.open("./spec/data/ruby_throated.jpg")
      )
    end
    
    before :each do
      get :index
      response.should be_success
    end
    
    it 'should show the image in-line as an <img> tag' do
      response.should have_tag(
        "img[src^=?]",
        "/file_column_image/image/#{@file_column_image.id}/ruby_throated.jpg"
      )
    end
  end

  describe '#create' do
    before :each do
      file = File.new './spec/data/ruby_throated.jpg'
      post :create, :file_column_image => {:image => file}
      @file_column_image = FileColumnImage.find_by_image 'ruby_throated.jpg'
    end
    
    it 'should save an image record' do
      @file_column_image.should_not be_nil
    end
    
    it 'should save the image locally' do
      assert(
        File.exist?(
          "./public/file_column_image/image/#{@file_column_image.id}/ruby_throated.jpg"
        )
      )
    end
  end
  
  describe '#new' do
    before :each do
      get :new
      response.should be_success
    end
    
    it "should have a multipart form" do
      response.should have_tag('form[enctype=multipart/form-data]')
    end
    
    it 'should have a file input for image' do
      response.body.should match(
        %r|<input[^>]*name="file_column_image\[image\]"[^>]*type="file"|
      )
    end
  end
  
  describe '#show' do
    before :all do
      @file_column_image = FileColumnImage.create!(
        :image => File.open("./spec/data/ruby_throated.jpg")
      )
    end
    
    before :each do
      get :show, :id => @file_column_image.id
      response.should be_success
    end
    
    it 'should show the image in-line as an <img> tag' do
      response.should have_tag(
        "img[src^=?]",
        "/file_column_image/image/#{@file_column_image.id}/ruby_throated.jpg"
      )
    end
  end
end
