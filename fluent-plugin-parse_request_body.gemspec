Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-parse_request_body'
  gem.version       = '0.0.9'
  gem.authors       = ['EkiSong']
  gem.email         = ['yifriday0614@gmail.com']
  gem.homepage      = 'https://github.com/yifriday/fluent-plugin-parse_request_body.git'
  gem.description   = %q{Fluentd plugin to parse request body.}
  gem.summary       = %q{Fluentd plugin to parse request body}
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  if defined?(RUBY_VERSION) && RUBY_VERSION > '2.2'
    gem.add_development_dependency "test-unit", '~> 3'
  end

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'appraisal'
  gem.add_runtime_dependency     'fluentd', ['>= 0.14.8', '< 2']
end
