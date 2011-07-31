require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::Images2IntegrationTest < ActionController::IntegrationTest
  def test_index
    Image.destroy_all
    @image = Image.create!(
      :image_file_name => '123.jpg', :image_content_type => 'image/jpeg', 
      :image_file_size => '456'
    )
    @path = "/images/#{@image.id}/original/123.jpg"
    get "/admin/images2"
    assert_response :success
    
    # should show the image in-line as an <img> tag
    assert_select("img[src=?]", @path)
    
    # should not show the image path on its own as a value
    assert_no_match(%r|<td[^>]*>#{@path}</td>|, response.body)
    
    # should show path text field
    assert_select('input[value=?]', "http://www.example.com#{@path}")
    
    # should not show an edit link since we can only create or index
    assert_select(
      'a[href=?]', "/admin/images2/edit/#{@image.id}", false
    )
      
    # should have a new link
    assert_select(
      "a[href=/admin/images2/new]", 'New image'
    )
  end
end
