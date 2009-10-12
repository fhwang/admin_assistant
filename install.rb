require 'fileutils'
require 'pathname'

outer = File.dirname(__FILE__)

# Delete test_rails_app and various doc directories, unless you're actually
# developing admin_assistant itself
test_rails_app = Pathname.new("#{outer}/test_rails_app").realpath.to_s
unless RAILS_ROOT == test_rails_app
  %w(doc test_rails_app website).each do |dir|
    FileUtils.rm_rf "#{outer}/#{dir}"
  end
end

# Copy over static assets
css_dir = "#{RAILS_ROOT}/public/stylesheets/admin_assistant"
FileUtils.mkdir(css_dir) unless File.exist?(css_dir)
FileUtils.cp_r(Dir.glob("#{outer}/lib/stylesheets/*"), css_dir)
FileUtils.copy(
  "#{outer}/lib/javascripts/admin_assistant.js",
  "#{RAILS_ROOT}/public/javascripts/admin_assistant.js"
)
images_dir = "#{RAILS_ROOT}/public/images/admin_assistant"
FileUtils.mkdir(images_dir) unless File.exist?(images_dir)
FileUtils.cp_r(Dir.glob("#{outer}/lib/images/*"), images_dir)

