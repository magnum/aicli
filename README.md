# aicli

Natural language to live shell commands — OpenAI & Anthropic.

Chat with the model and run suggested commands in your shell in one seamless flow.

The gem is named **aicli**; the shell command is **`ai`** (also available as `aicli`).

## Setup

> Requires Ruby 3.0+

1. Install the gem:

   ```sh
   gem install aicli
   ```

   Or from this repository:

   ```sh
   bundle install
   bundle exec rake install
   # or
   gem build aicli.gemspec && gem install ./aicli-*.gem
   ```

2. Choose a provider and set the matching API key.

   **OpenAI** (default) — key from [OpenAI](https://platform.openai.com/account/api-keys):

   ```sh
   ai config set PROVIDER=openai
   ai config set OPENAI_KEY=<your token>
   ```

   **Anthropic** — key from [Anthropic](https://console.anthropic.com/settings/keys):

   ```sh
   ai config set PROVIDER=anthropic
   ai config set ANTHROPIC_KEY=<your token>
   ```

   Or use the interactive UI (`ai config`) to pick provider, key, and model.
   Model lists come from the [RubyLLM](https://rubyllm.com/models/) registry.

   Config lives in `~/.aicli/config`. Chat/prompt history is stored in `~/.aicli/context` (last 40 messages) and reloaded on the next run.

## Usage

```bash
ai <prompt>
```

For example:

```bash
ai list all log files
```

Then you will get an output where you can choose to run the suggested command, revise it via a prompt, edit it, copy it, or cancel.

### Special characters

Some shells handle characters like `?` or `*` specially. Wrap the prompt in quotes if needed:

```bash
ai 'what is my ip address'
```

### Chat mode

```bash
ai chat
```

Ask for shell commands in a multi-turn conversation. When the assistant suggests a command in a code fence, you are asked whether to run it; after it runs (or you decline), chat continues. Press `Ctrl+d` to quit.

### Silent mode (skip explanations)

```bash
ai -s list all log files
```

Or save the preference:

```bash
ai config set SILENT_MODE=true
```

### Provider and model

```sh
ai config set PROVIDER=openai      # or anthropic
ai config set MODEL=gpt-4o-mini    # provider-specific model id
```

Defaults: `gpt-4o-mini` (OpenAI), `claude-sonnet-4-6` (Anthropic).

LLM calls go through [RubyLLM](https://rubyllm.com/), so chat streaming and model metadata stay provider-agnostic.

### Custom OpenAI API endpoint

Useful for OpenAI-compatible proxies (ignored for Anthropic):

```sh
ai config set OPENAI_API_ENDPOINT=<your proxy endpoint>
```

Default: `https://api.openai.com/v1`

### Set Language

| Language            | Key     |
| ------------------- | ------- |
| English             | en      |
| Simplified Chinese  | zh-Hans |
| Traditional Chinese | zh-Hant |
| Spanish             | es      |
| Japanese            | jp      |
| Korean              | ko      |
| French              | fr      |
| German              | de      |
| Russian             | ru      |
| Ukrainian           | uk      |
| Vietnamese          | vi      |
| Arabic              | ar      |
| Portuguese          | pt      |
| Turkish             | tr      |
| Indonesian          | id      |
| Italian             | it      |

```sh
ai config set LANGUAGE=zh-Hans
```

### Config UI

```bash
ai config
```

### Upgrading

```bash
ai --version
ai update
# or: gem update aicli
```

## Development

Run the local checkout (not the installed gem) with Bundler from this directory:

```sh
bundle install

bundle exec bin/ai --help
bundle exec bin/ai config
bundle exec bin/ai chat
bundle exec bin/ai list all log files
```

`bundle exec` loads dependencies from the Gemfile and code from `lib/`. `bin/aicli` is an alias of `bin/ai`.

Example config for local testing:

```sh
bundle exec bin/ai config set PROVIDER=openai
bundle exec bin/ai config set OPENAI_KEY=<your token>
# or: PROVIDER=anthropic + ANTHROPIC_KEY=<your token>
```

## Common Issues

### Rate limit / quota errors

Usually billing or quota on the configured provider (OpenAI or Anthropic). Check that provider’s console billing page and that the matching API key is set in `~/.aicli/config`.

## Motivation

I am not a bash wizard, and am dying for access to the copilot CLI, and got impatient.

## Credit

Started from [BuilderIO/ai-shell](https://github.com/BuilderIO/ai-shell) (MIT; copyright Builder.io 2023).
