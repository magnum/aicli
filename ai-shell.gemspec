# frozen_string_literal: true

require_relative 'lib/ai_shell/version'

Gem::Specification.new do |spec|
  spec.name          = 'ai-shell'
  spec.version       = AiShell::VERSION
  spec.authors       = ['Antonio Molinari']
  spec.email         = ['antoniomolinari@me.com']

  spec.summary       = 'A CLI that converts natural language to shell commands.'
  spec.description   = 'AI Shell turns natural language prompts into runnable shell commands via the OpenAI API. Ruby port inspired by BuilderIO/ai-shell.'
  spec.homepage      = 'https://github.com/magnum/ai-shell'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir[
    'lib/**/*',
    'bin/*',
    'locales/**/*',
    'LICENSE',
    'README.md',
    'CHANGELOG.md'
  ]
  spec.bindir        = 'bin'
  spec.executables   = ['ai', 'ai-shell']
  spec.require_paths = ['lib']

  spec.add_dependency 'clipboard', '~> 1.3'
  spec.add_dependency 'pastel', '~> 0.8'
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'tty-prompt', '~> 0.23'
  spec.add_dependency 'tty-spinner', '~> 0.9'
end
