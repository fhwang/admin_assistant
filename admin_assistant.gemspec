require 'rake'

Gem::Specification.new do |s|
  s.name = 'admin_assistant'
  s.version = '1.0.0'
  s.date = '2009-08-02'
  s.author = 'Francis Hwang'
  s.description = 'admin_assistant is a Rails plugin that automates a lot of features typically needed in admin interfaces.'
  s.summary = 'admin_assistant is a Rails plugin that automates a lot of features typically needed in admin interfaces.'
  s.email = 'sera@fhwang.net'
  s.homepage = 'http://github.com/fhwang/admin_assistant/tree/master'
  s.files = FileList[%w(
    MIT-LICENSE README *.rb Rakefile lib/*.rb lib/admin_assistant/*.rb 
    lib/admin_assistant/*/*.rb lib/images/*.png lib/javascripts/*.js
    lib/stylesheets/*.css lib/views/*.erb tasks/*.rake 
    vendor/ar_query/MIT-LICENSE vendor/ar_query/README vendor/ar_query/*.rb 
    vendor/ar_query/*/*.rb vendor/ar_query/*/*.rake
  )].to_a
  s.add_dependency 'mislav-will_paginate'
end
