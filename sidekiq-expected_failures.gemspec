# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/expected_failures/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-expected_failures"
  spec.version       = Sidekiq::ExpectedFailures::VERSION
  spec.authors       = ["Rafal Wojsznis"]
  spec.email         = ["rafal.wojsznis@gmail.com"]
  spec.description   = spec.summary = "If you don't rely on sidekiq' retry behavior, you handle exceptions on your own and want to keep track of them - this thing is for you."
  spec.homepage      = "https://github.com/emq/sidekiq-expected_failures"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 2.15.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "timecop", "~> 0.6.3"
  spec.add_development_dependency "mocha", "~> 0.14.0"
end
