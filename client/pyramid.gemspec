# -*- encoding: utf-8 -*-
require File.expand_path(File.join('..', 'lib', 'pyramid', 'version'), __FILE__)

Gem::Specification.new do |s|
  s.name = 'pyramid'
  s.version = Pyramid::VERSION.dup
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.authors = ['Brian Moseley']
  s.description = 'Pyramid service client'
  s.email = ['bcm@copious.com']
  s.homepage = 'http://github.com/utahstreetlabs/pyramid'
  s.rdoc_options = ['--charset=UTF-8']
  s.summary = "A client library for the Pyramid service"
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files -- lib/*`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_development_dependency('awesome_print')
  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')
  s.add_development_dependency('rspec', '~> 2.13.0')
  s.add_development_dependency('gemfury')
  s.add_runtime_dependency('ladon')
end
