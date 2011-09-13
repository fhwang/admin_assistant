class AdminAssistant
  module Helper
    def admin_assistant_includes(opts = {})
      ss_name = "admin_assistant/admin_assistant"
      ss_name << "_#{opts[:theme]}" if opts[:theme]
      tags = stylesheet_link_tag(ss_name)
      tags << stylesheet_link_tag("admin_assistant/token-input")
      js_dir =
        Pathname.new(Rails.root) + "public/javascripts/admin_assistant"
      Dir.entries(js_dir).each do |entry|
        if entry =~ /\.js$/
          tags << javascript_include_tag("admin_assistant/#{entry}")
        end
      end
      tags
    end
  end
end
