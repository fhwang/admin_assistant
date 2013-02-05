require 'grancher/task'
require 'rake'
require 'rake/testtask'

desc 'Default: run all specs across all supported Rails gem versions.'
task :default => :spec

desc 'Run all specs across all supported Rails gem versions.'
task :spec do
  supported_versions = %w(2.1.0 2.1.2 2.2.2 2.3.2 2.3.3 2.3.4)
  locally_installed_versions =
      `gem list --local rails`.split(/\n/).
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

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "admin_assistant"
    gem.summary = %Q{admin_assistant is a Rails plugin that automates a lot of features typically needed in admin interfaces.}
    gem.description = %Q{admin_assistant is a Rails plugin that automates a lot of features typically needed in admin interfaces.}
    gem.email = "sera@fhwang.net"
    gem.homepage = "http://github.com/fhwang/admin_assistant"
    gem.authors = ["Francis Hwang"]
    gem.add_dependency "will_paginate"
    gem.files.exclude "test_rails_app"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

