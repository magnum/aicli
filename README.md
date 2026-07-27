<h2 align="center">
   <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://cdn.builder.io/api/v1/image/assets%2FYJIGb4i01jvw0SRdL5Bt%2Fb5b9997cec2c4fffb3e5c5e9bb4fed7d">
      <img width="300" alt="AI Shell logo" src="https://cdn.builder.io/api/v1/image/assets%2FYJIGb4i01jvw0SRdL5Bt%2Fb7f9d2d9911a4199a9d26f8ba210b3f8">
    </picture>
</h2>

<h4 align="center">
   A CLI that converts natural language to shell commands.
</h4>

<p align="center">
   Inspired by the <a href="https://githubnext.com/projects/copilot-cli">GitHub Copilot X CLI</a>, but open source for everyone.
</p>

<br>

# AI Shell

Ruby port by [Antonio Molinari](https://github.com/magnum), inspired by the original [BuilderIO/ai-shell](https://github.com/BuilderIO/ai-shell) CLI.

## Setup

> Requires Ruby 3.0+

1. Install _ai shell_:

   ```sh
   gem install ai-shell
   ```

   Or from this repository:

   ```sh
   bundle install
   bundle exec rake install
   # or
   gem build ai-shell.gemspec && gem install ./ai-shell-*.gem
   ```

2. Retrieve your API key from [OpenAI](https://platform.openai.com/account/api-keys)

   > Note: If you haven't already, you'll have to create an account and set up billing.

3. Set the key so ai-shell can use it:

   ```sh
   ai config set OPENAI_KEY=<your token>
   ```

   This will create a `.ai-shell` file in your home directory.

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

Engage in a conversation with the AI directly through the CLI.

### Silent mode (skip explanations)

```bash
ai -s list all log files
```

Or save the preference:

```bash
ai config set SILENT_MODE=true
```

### Custom API endpoint

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
gem update ai-shell
```

Or:

```bash
ai update
```

## Development

```sh
bundle install
bundle exec bin/ai --help
bundle exec bin/ai config set OPENAI_KEY=<your token>
bundle exec bin/ai list all log files
```

## Common Issues

### 429 error

This is due to incorrect billing setup or excessive quota usage. Please follow [this guide](https://help.openai.com/en/articles/6891831-error-code-429-you-exceeded-your-current-quota-please-check-your-plan-and-billing-details) to fix it.

You can activate billing at [this link](https://platform.openai.com/account/billing/overview).

## Motivation

I am not a bash wizard, and am dying for access to the copilot CLI, and got impatient.

## Credit

- Ruby port by [Antonio Molinari](https://github.com/magnum)
- Inspired by [BuilderIO/ai-shell](https://github.com/BuilderIO/ai-shell)
- Thanks to GitHub Copilot for their amazing tools and the idea for this
- Thanks to Hassan and his work on [aicommits](https://github.com/Nutlope/aicommits), which inspired the workflow and some parts of the code and flows
- Original Node.js implementation by [Builder.io](https://www.builder.io)
