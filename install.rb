require 'fileutils'
require 'pathname'

outer = File.dirname(__FILE__)

# Delete rails_2_test and various doc directories, unless you're actually
# developing admin_assistant itself
test_rails_app = Pathname.new("#{outer}/rails_2_test").realpath.to_s
unless RAILS_ROOT == test_rails_app
  %w(doc rails_2_test website).each do |dir|
    FileUtils.rm_rf "#{outer}/#{dir}"
  end
end

# Copy over static assets
%w(stylesheets javascripts images).each do |asset_type|
  asset_dir = "#{Rails.root}/public/#{asset_type}/admin_assistant"
  FileUtils.mkdir(asset_dir) unless File.exist?(asset_dir)
  FileUtils.cp_r(Dir.glob("#{outer}/lib/#{asset_type}/*"), asset_dir)
end

