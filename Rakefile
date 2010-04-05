require 'rubygems'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'

$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), 'lib'))
$:.uniq!

require 'weld/version'

gemspec = Gem::Specification.new do |s|
  s.name     = 'weld'
  s.summary  = 'Combines and minifies CSS and JavaScript files at runtime and build time.'
  s.version  = "#{Weld::APP_VERSION}"
  s.author   = "#{Weld::APP_AUTHOR}"
  s.email    = "#{Weld::APP_EMAIL}"
  s.homepage = "#{Weld::APP_URL}"
  s.platform = Gem::Platform::RUBY

  s.executables           = ['weld']
  s.require_path          = 'lib'
  s.required_ruby_version = '>= 1.8.6'

  s.add_dependency('aws-s3',  '~> 0.6')
  s.add_dependency('sinatra', '~> 1.0')
  s.add_dependency('trollop', '~> 1.13')

  s.files = FileList[
    'LICENSE',
    'README.rdoc',
    'bin/weld',
    'examples/*.yaml',
    'lib/**/*.rb'
  ]
end

Rake::GemPackageTask.new(gemspec) do |p|
  p.need_tar = false
  p.need_zip = false
end

Rake::RDocTask.new do |rd|
  rd.main     = 'README.rdoc'
  rd.title    = 'Weld Documentation'
  rd.rdoc_dir = 'doc'

  rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')

  rd.options << '--line-numbers' << '--inline-source'
end
