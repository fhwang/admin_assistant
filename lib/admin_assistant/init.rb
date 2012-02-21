require 'fileutils'
require 'pathname'

class AdminAssistant
  def self.init
    gem_root = File.dirname(__FILE__) + "/../.."
    copy_into_public = %w(images)
    unless app_uses_sprockets?
      copy_into_public.concat(%w(stylesheets javascripts))
    end
    copy_into_public.each do |asset_type|
      asset_dir = "#{Rails.root}/public/#{asset_type}/admin_assistant"
      FileUtils.mkdir_p(asset_dir) unless File.exist?(asset_dir)
      FileUtils.cp_r(
        Dir.glob("#{gem_root}/vendor/assets/#{asset_type}/*"), asset_dir
      )
    end
  end
end

