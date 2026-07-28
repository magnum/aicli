<h2 align="center">
   <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://cdn.builder.io/api/v1/image/assets%2FYJIGb4i01jvw0SRdL5Bt%2Fb5b9997cec2c4fffb3e5c5e9bb4fed7d">
      <img width="300" alt="aicli logo" src="https://cdn.builder.io/api/v1/image/assets%2FYJIGb4i01jvw0SRdL5Bt%2Fb7f9d2d9911a4199a9d26f8ba210b3f8">
    </picture>
</h2>

<h4 align="center">
   A CLI that converts natural language to shell commands.
</h4>

<p align="center">
   Inspired by the <a href="https://githubnext.com/projects/copilot-cli">GitHub Copilot X CLI</a>, but open source for everyone.
</p>

<br>

# aicli

Ruby port by [Antonio Molinari](https://github.com/magnum), inspired by the original [BuilderIO/ai-shell](https://github.com/BuilderIO/ai-shell) CLI.

## Setup

> Requires Ruby 3.0+

1. Install _aicli_:

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
   aicli config set PROVIDER=openai
   aicli config set OPENAI_KEY=<your token>
   ```

   **Anthropic** — key from [Anthropic](https://console.anthropic.com/settings/keys):

   ```sh
   aicli config set PROVIDER=anthropic
   aicli config set ANTHROPIC_KEY=<your token>
   ```

   Or use the interactive UI (`aicli config`) to pick provider, key, and model.
   Model lists come from the [RubyLLM](https://rubyllm.com/models/) registry.

   Config lives in `~/.aicli/config`. Chat/prompt history is stored in `~/.aicli/context` (last 40 messages) and reloaded on the next run.

## Usage

```bash
aicli <prompt>
```

For example:

```bash
aicli list all log files
```

Then you will get an output where you can choose to run the suggested command, revise it via a prompt, edit it, copy it, or cancel.

The short alias `ai` is also available.

### Special characters

Some shells handle characters like `?` or `*` specially. Wrap the prompt in quotes if needed:

```bash
aicli 'what is my ip address'
```

### Chat mode

```bash
aicli chat
```

Ask for shell commands in a multi-turn conversation. When the assistant suggests a command in a code fence, you are asked whether to run it; after it runs (or you decline), chat continues. Press `Ctrl+d` to quit.

### Silent mode (skip explanations)

```bash
aicli -s list all log files
```

Or save the preference:

```bash
aicli config set SILENT_MODE=true
```

### Provider and model

```sh
aicli config set PROVIDER=openai      # or anthropic
aicli config set MODEL=gpt-4o-mini    # provider-specific model id
```

Defaults: `gpt-4o-mini` (OpenAI), `claude-sonnet-4-6` (Anthropic).

LLM calls go through [RubyLLM](https://rubyllm.com/), so chat streaming and model metadata stay provider-agnostic.

### Custom OpenAI API endpoint

Useful for OpenAI-compatible proxies (ignored for Anthropic):

```sh
aicli config set OPENAI_API_ENDPOINT=<your proxy endpoint>
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
aicli config set LANGUAGE=zh-Hans
```

### Config UI

```bash
aicli config
```

### Upgrading

```bash
aicli --version
gem update aicli
```

Or:

```bash
aicli update
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

`bin/aicli` is equivalent to `bin/ai`. `bundle exec` loads dependencies from the Gemfile and code from `lib/`.

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

- Ruby port by [Antonio Molinari](https://github.com/magnum)
- Inspired by [BuilderIO/ai-shell](https://github.com/BuilderIO/ai-shell)
- Thanks to GitHub Copilot for their amazing tools and the idea for this
- Thanks to Hassan and his work on [aicommits](https://github.com/Nutlope/aicommits), which inspired the workflow and some parts of the code and flows
- Original Node.js implementation by [Builder.io](https://www.builder.io)
