require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::FileColumnImages2Controller do
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
end
