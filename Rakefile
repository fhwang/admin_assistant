require 'grancher/task'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc 'Default: run all specs across all supported Rails gem versions.'
task :default => :spec

# run with rake publish
Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin' # automatically push too
  
  g.directory 'website'
end

desc 'Generate documentation for the admin_assistant plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'AdminAssistant'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Run all specs across all supported Rails gem versions.'
task :spec do
  supported_versions = %w(2.1.0 2.1.2 2.2.2 2.3.2 2.3.3 2.3.4)
  locally_installed_versions =
      `gem list --local rails`.lines.
          detect { |l| l=~ /^rails / }.strip.
          gsub(/^.*\((.*)\).*$/, '\1').split(/\s*,\s*/)
  missing = supported_versions - locally_installed_versions
  if !missing.empty?
    puts "Missing Rails versions #{missing.join(',')}; please install and then re-run tests"
  else
    cmd = "cd test_rails_app && " + (
      supported_versions.map { |version|
        "echo '===== Testing #{version} =====' && RAILS_GEM_VERSION=#{version} rake"
      }.join(" && ")
    )
    puts cmd
    puts `#{cmd}`
  end
end

