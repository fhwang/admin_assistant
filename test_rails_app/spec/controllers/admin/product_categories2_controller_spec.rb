require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ProductCategories2Controller do
  integrate_views

  describe '#create with 3 new valid product categories and 7 blanks' do
    before :each do
      ProductCategory.destroy_all
      post(
        :create,
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
      response.should_not be_error
    end
    
    it 'should create 3 product categories' do
      ProductCategory.count.should == 3
      %w(shiny bouncy sparkly).each do |name|
        ProductCategory.first(
          :conditions => {:category_name => name}
        ).should_not be_nil
      end
    end

    it 'should redirect to index' do
      response.should redirect_to(:action => 'index')
    end
  end

  describe '#create with 2 new valid product categories, 1 invalid product category, and 7 blanks' do
    before :each do
      ProductCategory.destroy_all
      ProductCategory.create! :category_name => 'shiny', :position => 1
      @orig_pc_count = ProductCategory.count
      post(
        :create,
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
      response.should be_success
    end

    it 'should not create any product categories' do
      ProductCategory.count.should == @orig_pc_count
    end

    it 'should render the error for the invalid product category' do
      response.body.should match(/has already been taken/)
    end
    
    it 'should move non-empty records to the top of the rendered form' do
      response.should have_tag("form") do
        with_tag(
          'input[name=?][value=?]', "product_category[a][category_name]",
          'shiny'
        )
        with_tag(
          'input[name=?][value=?]', "product_category[b][category_name]",
          'bouncy'
        )
        with_tag(
          'input[name=?][value=?]', "product_category[c][category_name]",
          'sparkly'
        )
      end
    end
    
    it 'should render the error directly above the row with the error in it' do
      response.should have_tag('form') do
        with_tag('table') do
          with_tag('tr') do
            with_tag('td', :text => /^\s*$/)
            with_tag(
              'td.errorExplanation:not([colspan])',
              :text => /Category name has already been taken/
            )
          end
          with_tag('td.fieldWithErrors') do
            with_tag(
              'input[name=?][value=?]', "product_category[a][category_name]",
              'shiny'
            )
          end
        end
      end
    end
    
    it 'should have 7 blank slots at the bottom' do
      'd'.upto('j') do |prefix|
        response.should have_tag(
          'input[name=?]', "product_category[#{prefix}][category_name]"
        )
      end
    end
  end
  
  describe '#create with nothing entered' do
    before :each do
      post(
        :create,
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
      response.should_not be_error
    end

    it 'should redirect to index' do
      response.should redirect_to(:action => 'index')
    end
  end
  
  describe '#edit' do
    before :all do
      ProductCategory.destroy_all
      @pc = ProductCategory.create!(
        :category_name => 'shiny', :position => 1
      )
    end
    
    before :each do
      get :edit, :id => @pc.id
    end
    
    it 'should show the form for one record at a time, like normal' do
      response.should have_tag(
        'form[action=?]', "/admin/product_categories2/update/#{@pc.id}"
      ) do
        with_tag(
          "input[name=?][value=?]", 'product_category[category_name]', 
          @pc.category_name
        )
      end
    end
  end

  describe '#index' do
    before :each do
      get :index
    end

    it "should use different text for the new link because we're doing multiple creates" do
      response.should have_tag(
        "a[href=/admin/product_categories2/new]", 'New product categories'
      )
    end
  end

  describe '#new' do
    before :each do
      get :new
    end

    it 'should show a form for 10 product categories at once' do
      response.should have_tag('form') do
        'a'.upto('j') do |i|
          with_tag 'input[name=?]', "product_category[#{i}][category_name]"
        end
        with_tag 'input[type=submit]'
      end
    end
  end
  
  describe '#update' do
    before :all do
      ProductCategory.destroy_all
      @pc = ProductCategory.create!(
        :category_name => 'shiny', :position => 1
      )
    end
    
    before :each do
      post(
        :update,
        :id => @pc.id, :product_category => {:category_name => 'SHINY'}
      )
    end
    
    it 'should update one record at a time' do
      @pc.reload
      @pc.category_name.should == 'SHINY'
    end
  end
end

