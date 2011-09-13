class AdminAssistant
  class MongoidColumn < ActiveRecordColumn
    def sort_possible?(model, total_entries)
      model.index_options.keys.include?(name.to_sym)
    end
  end
end
