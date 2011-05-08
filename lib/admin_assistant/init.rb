require 'fileutils'
require 'pathname'

class AdminAssistant
  def self.init
    gem_root = File.dirname(__FILE__) + "/../.."

    # Delete rails_3_test and various doc directories, unless you're actually
    # developing admin_assistant itself
    test_rails_app = Pathname.new("#{gem_root}/rails_3_test").realpath.to_s
    unless Rails.root.to_s == test_rails_app.to_s
      %w(doc rails_3_test website).each do |dir|
        FileUtils.rm_rf "#{gem_root}/#{dir}"
      end
    end
    
    # Copy over static assets
    %w(stylesheets javascripts images).each do |asset_type|
      asset_dir = "#{Rails.root}/public/#{asset_type}/admin_assistant"
      FileUtils.mkdir(asset_dir) unless File.exist?(asset_dir)
      FileUtils.cp_r(Dir.glob("#{gem_root}/lib/#{asset_type}/*"), asset_dir)
    end
  end
end

