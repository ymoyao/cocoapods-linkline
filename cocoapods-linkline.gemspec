# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-linkline/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-linkline'
  spec.version       = CocoapodsLinkline::VERSION
  spec.authors       = ['youhui']
  spec.email         = ['developer_yh@163.com']
  spec.description   = %q{A plug-in that can customize component dependencies, static libraries/dynamic libraries.}
  spec.summary       = %q{use :linkages => dynimic to define component all child dependencies with dynimic framework. \
                          use :linkage => static to component self with static framework.}
  spec.homepage      = 'https://github.com/ymoyao/cocoapods-linkline'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
