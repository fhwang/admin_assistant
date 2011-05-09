require 'fileutils'
require 'pathname'

class AdminAssistant
  def self.init
    gem_root = File.dirname(__FILE__) + "/../.."
    %w(stylesheets javascripts images).each do |asset_type|
      asset_dir = "#{Rails.root}/public/#{asset_type}/admin_assistant"
      FileUtils.mkdir(asset_dir) unless File.exist?(asset_dir)
      FileUtils.cp_r(Dir.glob("#{gem_root}/lib/#{asset_type}/*"), asset_dir)
    end
  end
end

