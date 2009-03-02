require 'rake'

Gem::Specification.new do |s|
  s.name = 'admin_assistant'
  s.version = '0.0.1'
  s.date = '2009-02-19'
  s.author = 'Francis Hwang'
  s.description = ''
  s.summary = ''
  s.email = 'sera@fhwang.net'
  s.homepage = 'http://github.com/fhwang/admin_assistant/tree/master'
  s.files = FileList[
    'lib/*.rb', 'MIT-LICENSE', 'README', '*.rb', 'spec/*.rb', 
    'tasks/*.rake', 'lib/views/*.erb', 'Rakefile'
  ].to_a
  s.add_dependency 'ar_query'
  s.add_dependency 'mislav-will_paginate'
end
