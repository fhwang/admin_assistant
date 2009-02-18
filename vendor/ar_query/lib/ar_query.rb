require 'delegate'

class ARQuery < Hash
  attr_accessor :bind_vars, :boolean_join
  attr_reader   :condition_sqls
  
  def initialize(initial_values={})
    super nil
    initial_values.each do |k,v| self[k] = v; end
    @bind_vars = []
    @condition_sqls = []
    @boolean_join = :and
  end
    
  def []( key )
    if (key == :conditions) && !@condition_sqls.empty?
      join_str = @boolean_join == :and ? ' AND ' : ' OR '
      condition_sql =
          @condition_sqls.map { |c_sql| "(#{c_sql})" }.join(join_str)
      @bind_vars.empty? ? condition_sql : [ condition_sql, *@bind_vars ]
    else
      super
    end
  end
end
