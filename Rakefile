require 'rake'
require 'rake/testtask'

desc 'Default: run all tests across all supported Rails gem versions.'
task :default => :test

desc 'Run all tests across all supported Rails gem versions.'
task :test do
  ENV['CMD'] = 'rake'
  Rake::Task[:run_everywhere].invoke
end

desc 'Run CMD in all tested rails environments.'
task :run_everywhere do
  core_cmd = ENV['CMD']
  cmds = []
  base = Dir.pwd
  version_dirs = %w(rails_3_1)
  version_dirs.each do |dir|
    path = File.join(base, dir)
    cmds << "cd #{path} && bundle exec #{core_cmd}"
  end
  # alternate config tests
  path = File.join(base, 'rails_3_1')
  cmds << "cd #{path} && AA_CONFIG=2 bundle exec #{core_cmd}"
  cmds.each do |cmd|
    puts cmd
    puts `#{cmd}`
    puts
  end  
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
    gem.add_dependency "will_paginate", "~> 3.0"
    gem.add_dependency "dynamic_form"
    gem.files.exclude "rails_3_1/**/*"
    gem.license = 'MIT'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

