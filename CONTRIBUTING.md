# Contribution Guide

## Setting up the project

Requires Ruby 3.0+.

Install dependencies with Bundler:

```sh
bundle install
```

## Running locally

```sh
bundle exec bin/aicli --help
bundle exec bin/aicli config set PROVIDER=openai
bundle exec bin/aicli config set OPENAI_KEY=<your token>
# or: PROVIDER=anthropic + ANTHROPIC_KEY=<your token>
bundle exec bin/aicli list all log files
```

## Building the gem

```sh
gem build aicli.gemspec
gem install ./aicli-*.gem
```

Or with Rake:

```sh
bundle exec rake install
```

## Project structure

```
bin/          # Executables (aicli, ai)
lib/aicli/    # Ruby source
locales/      # i18n YAML files
```
