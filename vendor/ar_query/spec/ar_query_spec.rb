require File.dirname(__FILE__) + '/../lib/ar_query'

describe ARQuery do
  describe '#initialize with no values' do
    before :all do
      ar_query = ARQuery.new
      @hash = ar_query.to_hash
    end
    
    it 'should not have conditions' do
      @hash[:conditions].should be_nil
    end
    
    it 'should not have joins' do
      @hash[:joins].should be_nil
    end
    
    it 'should not let you assign like a hash' do
      lambda {
        @ar_query[:conditions] = "foo = 'bar'"
      }.should raise_error(NoMethodError)
      lambda {
        @ar_query[:joins] = "foo = 'bar'"
      }.should raise_error(NoMethodError)
    end
  end
  
  describe '#initialize with values' do
    before :all do
      @ar_query = ARQuery.new(:order => 'id desc', :limit => 25)
      @hash = @ar_query.to_hash
    end
    
    it 'should have those values in the hash' do
      @hash[:order].should == 'id desc'
      @hash[:limit].should == 25
    end
    
    it 'should not have other values in the hash' do
      @hash[:conditions].should be_nil
    end
  end
  
  describe "#condition_sqls <<" do
    before :all do
      @ar_query = ARQuery.new
      @ar_query.condition_sqls << "fname is not null"
      @ar_query.condition_sqls << "lname is not null"
    end
    
    it 'should join the conditions with an AND' do
      @ar_query.to_hash[:conditions].should ==
          "(fname is not null) AND (lname is not null)"
    end
    
    it "should prevent you from appending nil" do
      lambda { @ar_query.condition_sqls << nil }.should raise_error(
        ArgumentError,
        "Tried appending nil to ARQuery::Condition::SQLs: Only strings are allowed"
      )
    end
    
    it "should prevent you from appending a value besides a string" do
      lambda { @ar_query.condition_sqls << 55 }.should raise_error(
        ArgumentError,
        "Tried appending 55 to ARQuery::Condition::SQLs: Only strings are allowed"
      )
    end
  end
  
  describe '#condition_sqls << with OR as the boolean join' do
    before :all do
      @ar_query = ARQuery.new
      @ar_query.boolean_join = :or
      @ar_query.condition_sqls << "fname is not null"
      @ar_query.condition_sqls << "lname is not null"
    end
    
    it 'should join the conditions with an OR' do
      @ar_query.to_hash[:conditions].should ==
          "(fname is not null) OR (lname is not null)"
    end
  end
  
  describe '[:conditions]' do
    describe 'with bind vars' do
      before :all do
        @ar_query = ARQuery.new
        @ar_query.condition_sqls << "fname = ?"
        @ar_query.condition_sqls << "lname = ?"
      end
      
      describe 'using appends' do
        before :all do
          @ar_query.condition_bind_vars << 'Francis'
          @ar_query.condition_bind_vars << 'Hwang'
        end
        
        it 'should put the bind_vars at the end of the conditions array' do
          @ar_query.to_hash[:conditions].should ==
            [ "(fname = ?) AND (lname = ?)", 'Francis', 'Hwang' ]
        end
      end
      
      describe 'using assignment' do
        before :all do
          @ar_query.condition_bind_vars = %w( Francis Hwang )
        end
        
        it 'should put the bind_vars at the end of the conditions array' do
          @ar_query.to_hash[:conditions].should ==
            [ "(fname = ?) AND (lname = ?)", 'Francis', 'Hwang' ]
        end
      end
    end
  end
  
  describe 'with a nested condition' do
    before :all do
      @ar_query = ARQuery.new
      @ar_query.condition_sqls << "fname = ?"
      @ar_query.condition_bind_vars << 'Francis'
      @ar_query.add_condition do |cond|
        cond.boolean_join = :or
        cond.sqls << 'lname = ?'
        cond.sqls << 'lname = ?'
        cond.bind_vars << 'Hwang'
        cond.bind_vars << 'Bacon'
        cond.ar_query.should == @ar_query
      end
    end
    
    it 'should generate nested conditions in SQL' do
      @ar_query.to_hash[:conditions].should == [
        "(fname = ?) AND ((lname = ?) OR (lname = ?))",
        'Francis', 'Hwang', 'Bacon'
      ]
    end
  end
  
  describe "when using the nested condition syntax even though the query isn't nested" do
    before :all do
      @ar_query = ARQuery.new
      @ar_query.add_condition do |cond|
        cond.boolean_join = :or
        cond.sqls << "fname = ?"
        cond.bind_vars << 'Chunky'
      end
    end
    
    it 'should generate the non-nested condition in SQL' do
      @ar_query.to_hash[:conditions].should == ["(fname = ?)", 'Chunky']
    end
  end
  
  describe 'when nesting the nested condition unnecessarily' do
    before :all do
      @ar_query = ARQuery.new
      @ar_query.add_condition do |cond|
        cond.add_condition do |subcond|
          subcond.boolean_join = :or
          subcond.sqls << "fname = ?"
          subcond.bind_vars << 'Chunky'
        end
      end
    end
    
    it 'should generate the non-nested condition in SQL' do
      @ar_query.to_hash[:conditions].should == ["(fname = ?)", 'Chunky']
    end
  end
  
  describe '#joins <<' do
    describe 'when there are no joins to start' do
      before :all do
        @ar_query = ARQuery.new
        @ar_query.joins << :user
      end
      
      it 'should result in an array of 1 join' do
        @ar_query.to_hash[:joins].should == [:user]
      end
    end
    
    describe 'when it was initialized with one join' do
      before :all do
        @ar_query = ARQuery.new :joins => :user
        @ar_query.joins << :tags
      end
      
      it 'should result in an array of 2 joins' do
        @ar_query.to_hash[:joins].should == [:user, :tags]
      end
    end
    
    describe 'when there are already two joins' do
      before :all do
        @ar_query = ARQuery.new :joins => [:user, :tags]
        @ar_query.joins << :images
      end
      
      it 'should result in 3 joins' do
        @ar_query.to_hash[:joins].should == [:user, :tags, :images]
      end
    end
    
    describe 'when a duplicate join is being appended' do
      before :all do
        @ar_query = ARQuery.new :joins => [:user, :tags]
        @ar_query.joins << :user
      end

      it 'should not keep the array of joins unique' do
        @ar_query.to_hash[:joins].should == [:user, :tags]
      end
    end
    
    describe 'when the same association has already been :included' do
      before :all do
        @ar_query = ARQuery.new :include => 'user'
        @ar_query.joins << :user
      end
      
      it 'should not include the association in the join' do
        @ar_query.to_hash[:joins].should be_nil
      end
    end
  end
  
  describe '#total_entries =' do
    before :all do
      @ar_query = ARQuery.new
      @ar_query.total_entries = 25
    end
    
    it 'should set [:total_entries]' do
      @ar_query.to_hash[:total_entries].should == 25
    end
  end
end
