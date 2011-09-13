require 'grancher/task'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc 'Default: run all specs across all supported Rails gem versions.'
task :default => :test

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
task :test do
  base = Dir.pwd
  version_dirs = %w(rails_3_0 rails_3_1)
  version_dirs.each do |dir|
    path = File.join(base, dir)
    cmd = "cd #{path} && bundle exec rake"
    puts cmd
    puts `#{cmd}`
  end
  # alternate config tests
  path = File.join(base, 'rails_3_0')
  cmd = "cd #{path} && AA_CONFIG=2 bundle exec rake"
  puts cmd
  puts `#{cmd}`
end

desc 'Run a local copy of jekyll for previewing the documentation site.'
task :preview_website do
  cmd = 'cd website && jekyll --auto --server --base-url "/admin_assistant/"'
  puts cmd
  puts `#{cmd}`
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "admin_assistant"
    gem.summary = %Q{admin_assistant is a Rails plugin that automates a lot of features typically needed in admin interfaces.}
    gem.description = %Q{admin_assistant is a Rails plugin that automates a lot of features typically needed in admin interfaces.}
    gem.email = "sera@fhwang.net"
    gem.homepage = "http://github.com/fhwang/admin_assistant"
    gem.authors = ["Francis Hwang"]
    gem.add_dependency "will_paginate", "3.0"
    gem.add_dependency "dynamic_form"
    gem.files.exclude "rails_3_0/**/*"
    gem.files.exclude "rails_3_1/**/*"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

