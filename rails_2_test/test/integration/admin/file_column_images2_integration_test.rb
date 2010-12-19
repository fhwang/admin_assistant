require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::FileColumnImages2IntegrationTest < 
      ActionController::IntegrationTest
  
  def test_index
    @file_column_image = FileColumnImage.create!(
      :image => File.open("./test/data/ruby_throated.jpg")
    )
    get "/admin/file_column_images2"
    assert_response :success

    # should show the image in-line as an <img> tag
    assert_select(
      "img[src^=?][width=300][height=500]",
      "/file_column_image/image/#{@file_column_image.id}/ruby_throated.jpg"
    )
  end
end
