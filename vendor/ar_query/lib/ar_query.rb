class ARQuery
  attr_reader :joins
  
  def initialize(simple_values={})
    @simple_values = simple_values
    @base_condition = Condition.new self
    @joins = UniqueArray.new simple_values[:joins]
  end

  def method_missing(sym, *args)
    if sym == :total_entries=
      @simple_values[:total_entries] = args.first
    elsif [:has_conditions?, :boolean_join=].include?(sym)
      @base_condition.send(sym, *args)
    else
      super
    end
  end
  
  def add_condition(&block)
    if @base_condition.has_conditions?
      @base_condition.add_condition do |nested|
        block.call nested
      end
    else
      block.call @base_condition
    end
  end
  
  def condition_bind_vars
    @base_condition.bind_vars
  end
  
  def condition_bind_vars=(arg)
    @base_condition.bind_vars = arg
  end
  
  def condition_sqls
    @base_condition.sqls
  end
  
  def has_joins?
    !@joins.empty?
  end
  
  def to_hash
    hash = @simple_values.dup
    hash[:conditions] = @base_condition.to_conditions if has_conditions?
    hash[:joins] = @joins if has_joins?
    hash
  end
  
  class Condition
    attr_accessor :bind_vars, :boolean_join
    attr_reader :ar_query, :sqls
    
    def initialize(ar_query)
      @ar_query = ar_query
      @bind_vars = []
      @sqls = SQLs.new
      @boolean_join = :and
      @children = []
    end
  
    def has_conditions?
      !@sqls.empty?
    end
    
    def add_condition(&block)
      @children << Condition.new(@ar_query)
      yield @children.last
    end
    
    def to_conditions
      join_str = @boolean_join == :and ? ' AND ' : ' OR '
      binds = @bind_vars.dup || []
      condition_sql_fragments = @sqls.map { |c_sql| "(#{c_sql})" }
      @children.each do |child|
        sub_conditions = child.to_conditions
        if sub_conditions.is_a?(Array)
          sql = sub_conditions.first
          sub_binds = sub_conditions[1..-1]
          condition_sql_fragments << "(#{sql})"
          binds.concat sub_binds
        else
          condition_sql_fragments << "(#{sub_conditions})"
        end
      end
      condition_sql = condition_sql_fragments.join(join_str)
      binds.empty? ? condition_sql : [ condition_sql, *binds ]
    end
  
    class SQLs < Array
      def <<(elt)
        if elt.is_a?(String)
          super
        else
          raise(
            ArgumentError,
            "Tried appending #{elt.inspect} to ARQuery::Condition::SQLs: Only strings are allowed"
          )
        end
      end
    end
  end
  
  class UniqueArray < Array
    def initialize(values)
      super()
      if values
        values = [values] unless values.is_a?(Array)
        values.each do |value| self << value; end
      end
    end
    
    def <<(value)
      super
      uniq!
    end
  end
end
