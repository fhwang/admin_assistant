# Removing directories that would be spammy if you were just using this as a 
# plugin
FileUtils.rm_rf "#{File.dirname(__FILE__)}/doc"
FileUtils.rm_rf "#{File.dirname(__FILE__)}/test_rails_app"

