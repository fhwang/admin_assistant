class AdminAssistant
  class Model
    def initialize(ar_model)
      @ar_model = ar_model
    end
    
    def accessors
      @ar_model.instance_methods.
          select { |m| m =~ /=$/ }.
          map { |m| m.gsub(/=/, '')}.
          select { |m| @ar_model.instance_methods.include?(m) }
    end
  
    def belongs_to_associations
      @ar_model.reflect_on_all_associations.select { |assoc|
        assoc.macro == :belongs_to
      }
    end
    
    def belongs_to_assoc(association_name)
      belongs_to_associations.detect { |assoc|
        assoc.name.to_s == association_name.to_s
      }
    end
    
    def belongs_to_assoc_by_foreign_key(foreign_key)
      belongs_to_associations.detect { |assoc|
        assoc.association_foreign_key == foreign_key
      }
    end
    
    def belongs_to_assoc_by_polymorphic_type(name)
      if name =~ /^(.*)_type/
        belongs_to_associations.detect { |assoc|
          assoc.options[:polymorphic] && $1 == assoc.name.to_s
        }
      end
    end
    
    def default_column_names
      @ar_model.columns.reject { |ar_column|
        %w(id created_at updated_at).include?(ar_column.name)
      }.map { |ar_column| ar_column.name }
    end
  
    def has_many_assoc(association_name)
      @ar_model.reflect_on_all_associations.select { |assoc|
        assoc.macro == :has_many
      }.detect { |assoc|
        assoc.name.to_s == association_name.to_s
      }
    end
    
    def paperclip_attachments
      pa = []
      if @ar_model.respond_to?(:attachment_definitions)
        if @ar_model.attachment_definitions
          pa = @ar_model.attachment_definitions.map { |name, definition|
            name
          }
        end
      end
      pa
    end
  
    def searchable_columns
      @ar_model.columns.select { |column|
        [:string, :text].include?(column.type)
      }
    end
  end
end
