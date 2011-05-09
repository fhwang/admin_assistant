require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::ProductCategories2IntegrationTest < 
      ActionController::IntegrationTest
  def test_create_with_3_new_valid_product_categories_and_7_blanks
    ProductCategory.destroy_all
    post(
      "/admin/product_categories2",
      :product_category => {
        'a' => {'category_name' => 'shiny', 'position' => 1},
        'b' => {'category_name' => 'bouncy', 'position' => 2},
        'c' => {'category_name' => 'sparkly', 'position' => 3},
        'd' => {'category_name' => ''},
        'e' => {'category_name' => ''},
        'f' => {'category_name' => ''},
        'g' => {'category_name' => ''},
        'h' => {'category_name' => ''},
        'i' => {'category_name' => ''},
        'j' => {'category_name' => ''},
      }
    )
    
    # should create 3 product categories
    assert_equal(3, ProductCategory.count)
    %w(shiny bouncy sparkly).each do |name|
      assert_not_nil(
        ProductCategory.first(:conditions => {:category_name => name})
      )
    end

    # should redirect to index
    assert_redirected_to(:action => 'index')
  end

  def test_create_with_2_new_valid_product_categories_1_invalid_product_category_and_7_blanks
    ProductCategory.destroy_all
    ProductCategory.create! :category_name => 'shiny', :position => 1
    @orig_pc_count = ProductCategory.count
    post(
      "/admin/product_categories2",
      :product_category => {
        'a' => {'category_name' => ''},
        'b' => {'category_name' => ''},
        'c' => {'category_name' => 'shiny', :position => 2},
        'd' => {'category_name' => ''},
        'e' => {'category_name' => 'bouncy', :position => 3},
        'f' => {'category_name' => ''},
        'g' => {'category_name' => 'sparkly', :position => 4},
        'h' => {'category_name' => ''},
        'i' => {'category_name' => ''},
        'j' => {'category_name' => ''},
      }
    )
    assert_response :success

    # should not create any product categories
    assert_equal(@orig_pc_count, ProductCategory.count)

    # should render the error for the invalid product category
    assert_match(/has already been taken/, response.body)
    
    # should move non-empty records to the top of the rendered form
    assert_select("form") do
      assert_select(
        'input[name=?][value=?]', "product_category[a][category_name]",
        'shiny'
      )
      assert_select(
        'input[name=?][value=?]', "product_category[b][category_name]",
        'bouncy'
      )
      assert_select(
        'input[name=?][value=?]', "product_category[c][category_name]",
        'sparkly'
      )
    end
    
    # should render the error directly above the row with the error in it
    assert_select('form') do
      assert_select('table') do
        assert_select('tr') do
          assert_select('td', :text => /^\s*$/)
          assert_select(
            'td.errorExplanation:not([colspan])',
            :text => /Category name has already been taken/
          )
        end
        assert_select('td.field_with_errors') do
          assert_select(
            'input[name=?][value=?]', "product_category[a][category_name]",
            'shiny'
          )
        end
      end
    end
    
    # should have 7 blank slots at the bottom
    'd'.upto('j') do |prefix|
      assert_select(
        'input[name=?]', "product_category[#{prefix}][category_name]"
      )
    end
  end
  
  def test_create_with_nothing_entered
    post(
      "/admin/product_categories2",
      :product_category => {
        'a' => {'category_name' => ''},
        'b' => {'category_name' => ''},
        'c' => {'category_name' => ''},
        'd' => {'category_name' => ''},
        'e' => {'category_name' => ''},
        'f' => {'category_name' => ''},
        'g' => {'category_name' => ''},
        'h' => {'category_name' => ''},
        'i' => {'category_name' => ''},
        'j' => {'category_name' => ''},
      }
    )

    # should redirect to index
    assert_redirected_to(:action => 'index')
  end
  
  def test_edit
    ProductCategory.destroy_all
    @pc = ProductCategory.create!(
      :category_name => 'shiny', :position => 1
    )
    get "/admin/product_categories2/#{@pc.id}/edit"
    
    # should show the form for one record at a time, like normal
    assert_select(
      'form[action=?]', "/admin/product_categories2/#{@pc.id}"
    ) do
      assert_select(
        "input[name=?][value=?]", 'product_category[category_name]', 
        @pc.category_name
      )
    end
  end

  def test_index
    get "/admin/product_categories2"

    # should use different text for the new link because we're doing multiple creates
    assert_select(
      "a[href=/admin/product_categories2/new]", 'New product categories'
    )
  end
  
  def test_new
    get "/admin/product_categories2/new"

    # should show a form for 10 product categories at once
    assert_select('form') do
      'a'.upto('j') do |i|
        assert_select 'input[name=?]', "product_category[#{i}][category_name]"
      end
      assert_select 'input[type=submit]'
    end
  end
  
  def test_update
    ProductCategory.destroy_all
    @pc = ProductCategory.create!(
      :category_name => 'shiny', :position => 1
    )
    put(
      "/admin/product_categories2/#{@pc.id}",
      :product_category => {:category_name => 'SHINY'}
    )
    
    # should update one record at a time
    @pc.reload
    assert_equal('SHINY', @pc.category_name)
  end
end
