class AdminAssistant
  class MongoidColumn < ActiveRecordColumn
    def sort_possible?(total_entries)
      YapShow.index_options.keys.include?(name.to_sym)
    end
  end
end
