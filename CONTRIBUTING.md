# Contribution Guide

## Setting up the project

Requires Ruby 3.0+.

Install dependencies with Bundler:

```sh
bundle install
```

## Running locally

```sh
bundle exec bin/ai --help
bundle exec bin/ai config set OPENAI_KEY=<your token>
bundle exec bin/ai list all log files
```

## Building the gem

```sh
gem build ai-shell.gemspec
gem install ./ai-shell-*.gem
```

Or with Rake:

```sh
bundle exec rake install
```

## Project structure

```
bin/           # Executables (ai, ai-shell)
lib/ai_shell/  # Ruby source
locales/       # i18n JSON files
```
