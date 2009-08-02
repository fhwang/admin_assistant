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
  versions = %w(2.1.0 2.1.2 2.2.2 2.3.2 2.3.3)
  cmd = "cd test_rails_app && " + (versions.map { |version|
    "echo '===== Testing #{version} =====' && RAILS_GEM_VERSION=#{version} rake"
  }.join(" && "))
  puts cmd
  puts `#{cmd}`
end

