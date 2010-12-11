require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::FileColumnImagesIntegrationTest < 
      ActionController::IntegrationTest
  
  def test_index
    @file_column_image = FileColumnImage.create!(
      :image => File.open("./spec/data/ruby_throated.jpg")
    )
    get "/admin/file_column_images"
    assert_response :success
    
    # should show the image in-line as an <img> tag
    assert_select(
      "img[src^=?]",
      "/file_column_image/image/#{@file_column_image.id}/ruby_throated.jpg"
    )
  end

  def test_create
    FileColumnImage.destroy_all
    post(
      "/admin/file_column_images/create",
      :file_column_image => {
        :image => fixture_file_upload('../../spec/data/ruby_throated.jpg')
      },
      :html => {:multipart => true}
    )
    @file_column_image = FileColumnImage.find_by_image 'ruby_throated.jpg'
    
    # should save an image record
    assert_not_nil @file_column_image
    
    # should save the image locally
    assert(
      File.exist?(
        "./public/file_column_image/image/#{@file_column_image.id}/ruby_throated.jpg"
      )
    )
  end
  
  def test_new
    get "/admin/file_column_images/new"
    assert_response :success
    
    # should have a multipart form
    assert_select('form[enctype=multipart/form-data]')
    
    # should have a file input for image
    assert_match(
      %r|<input[^>]*name="file_column_image\[image\]"[^>]*type="file"|,
      response.body
    )
  end
  
  def test_show
    @file_column_image = FileColumnImage.create!(
      :image => File.open("./spec/data/ruby_throated.jpg")
    )
    get "/admin/file_column_images/show/#{@file_column_image.id}"
    assert_response :success
    
    # should show the image in-line as an <img> tag
    assert_select(
      "img[src^=?]",
      "/file_column_image/image/#{@file_column_image.id}/ruby_throated.jpg"
    )
  end
end
