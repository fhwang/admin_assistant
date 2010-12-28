class AdminAssistant
  module Helper
    def admin_assistant_includes(opts = {})
      theme = opts[:theme] || 'default'
      tags = stylesheet_link_tag("admin_assistant/#{theme}")
      js_dir = Pathname.new(Rails.root) + "public/javascripts/admin_assistant"
      Dir.entries(js_dir).each do |entry|
        if entry =~ /\.js$/
          tags << javascript_include_tag("admin_assistant/#{entry}")
        end
      end
      tags
    end
  end
end
