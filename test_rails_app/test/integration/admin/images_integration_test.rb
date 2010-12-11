require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::ImagesIntegrationTest < ActionController::IntegrationTest
  def test_index
    @image = Image.create!(
      :image_file_name => '123.jpg', :image_content_type => 'image/jpeg', 
      :image_file_size => '456'
    )
    get "/admin/images"
    assert_response :success
    
    # should show the image in-line as an <img> tag
    assert_select("img[src=/images/#{@image.id}/original/123.jpg]")
    
    # should not show paperclip-fields
    assert_no_match(/image_file_name/, response.body)
    assert_no_match(/image_content_type/, response.body)
    assert_no_match(/image_file_size/, response.body)
    assert_no_match(/image_updated_at/, response.body)
  end
  
  def test_create
    file = File.new './spec/data/ruby_throated.jpg'
    post(
      "/admin/images/create",
      :image => {
        :image => fixture_file_upload('../../spec/data/ruby_throated.jpg')
      },
      :html => {:multipart => true}
    )
    @image = Image.find_by_image_file_name 'ruby_throated.jpg'
    
    # should save an image record
    assert_not_nil @image
    
    # should save the image locally
    assert(
      File.exist?("./public/images/#{@image.id}/original/ruby_throated.jpg")
    )
  end
  
  def test_new
    get "/admin/images/new"
    assert_response :success
    
    # should have a multipart form
    assert_select('form[enctype=multipart/form-data]')
    
    # should have a file input for image
    assert_match(
      %r|<input[^>]*name="image\[image\]"[^>]*type="file"|,
      response.body
    )
    
    # should not show paperclip-fields
    assert_no_match(/image_file_name/, response.body)
    assert_no_match(/image_content_type/, response.body)
    assert_no_match(/image_file_size/, response.body)
    assert_no_match(/image_updated_at/, response.body)
  end
  
  def test_show
    @image = Image.create!(
      :image_file_name => '123.jpg', :image_content_type => 'image/jpeg', 
      :image_file_size => '456'
    )
    get "/admin/images/show/#{@image.id}"
    assert_response :success
    
    # should show the image in-line as an <img> tag
    assert_select("img[src=/images/#{@image.id}/original/123.jpg]")
    
    # should not show paperclip-fields
    assert_no_match(/image_file_name/, response.body)
    assert_no_match(/image_content_type/, response.body)
    assert_no_match(/image_file_size/, response.body)
    assert_no_match(/image_updated_at/, response.body)
  end
end
