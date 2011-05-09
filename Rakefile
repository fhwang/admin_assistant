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
  supported_versions = %w(3.0.6)
  locally_installed_versions =
      `gem list --local rails`.split(/\n/).
          detect { |l| l=~ /^rails / }.strip.
          gsub(/^.*\((.*)\).*$/, '\1').split(/\s*,\s*/)
  missing = supported_versions - locally_installed_versions
  if !missing.empty?
    puts "Missing Rails versions #{missing.join(',')}; please install and then re-run tests"
  else
    cmd = "cd rails_3_test && " + (
      supported_versions.map { |version|
        "echo '===== Testing #{version} =====' && RAILS_GEM_VERSION=#{version} rake"
      }.join(" && ")
    )
    puts cmd
    puts `#{cmd}`
  end
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
    gem.add_dependency "will_paginate", "~> 3.0.pre2"
    gem.add_dependency "dynamic_form"
    gem.files.exclude "rails_2_test"
    gem.files.exclude "rails_3_test"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

