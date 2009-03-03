require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Images2Controller do
  integrate_views
  
  describe '#index' do
    before :all do
      @image = Image.create!(
        :image_file_name => '123.jpg', :image_content_type => 'image/jpeg', 
        :image_file_size => '456'
      )
      @path = "/images/#{@image.id}/original/123.jpg"
    end
    
    before :each do
      get :index
      response.should be_success
    end
    
    it 'should show the image in-line as an <img> tag' do
      response.should have_tag("img[src=?]", @path)
    end
    
    it 'should not show the image path on its own as a value' do
#puts response.body
      response.should_not have_tag('td', @path)
    end
  end
end
