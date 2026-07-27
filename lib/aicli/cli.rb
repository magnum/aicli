# frozen_string_literal: true

require 'thor'
require 'pastel'

module AiCli
  class CLI < Thor
    KNOWN_COMMANDS = %w[config chat update help version tree].freeze

    def self.exit_on_failure?
      true
    end

    def self.start(given_args = ARGV, config = {})
      args = given_args.dup

      # Extract global flags that may appear before the prompt text
      silent = args.delete('--silent') || args.delete('-s')
      version_flag = args.delete('--version') || args.delete('-v')
      help_flag = args.delete('--help') || args.delete('-h')

      if version_flag
        puts AiCli::VERSION
        return
      end

      if help_flag && (args.empty? || !KNOWN_COMMANDS.include?(args.first))
        new.help
        return
      end

      # Prompt flag: -p / --prompt
      prompt_from_flag = nil
      if (idx = args.index('-p') || args.index('--prompt'))
        prompt_from_flag = args[idx + 1]
        args.slice!(idx, 2)
      end

      first = args.first

      if first.nil? || !KNOWN_COMMANDS.include?(first)
        # Treat remaining args as the natural-language prompt
        prompt_text = prompt_from_flag || args.join(' ')
        invoke_prompt(prompt_text, silent: !silent.nil?)
        return
      end

      # Rebuild argv for Thor subcommands, preserving silent if relevant
      thor_args = args
      thor_args = ['--silent'] + thor_args if silent && first == 'chat'
      super(thor_args, config)
    end

    def self.invoke_prompt(prompt_text, silent: false)
      pastel = Pastel.new

      begin
        config = Helpers::Config.get
        Helpers::I18n.set_language(config['LANGUAGE'])
      rescue StandardError
        Helpers::I18n.set_language('en')
      end

      Prompt.run(use_prompt: prompt_text, silent_mode: silent)
    rescue Helpers::KnownError, StandardError => e
      puts "\n#{pastel.red('✖')} #{e.message}"
      Helpers::Error.handle_cli_error(e)
      exit 1
    end

    desc 'config [MODE] [KEY=VALUE...]', 'Configure the CLI'
    def config(mode = nil, *key_values)
      init_i18n
      Commands::Config.run(mode, *key_values)
    end

    desc 'chat', 'Start a new chat session'
    def chat
      init_i18n
      Commands::Chat.run
    end

    desc 'update', 'Update aicli to the latest version'
    def update
      init_i18n
      Commands::Update.run
    end

    map %w[--version -v] => :__print_version
    desc 'version', 'Print version'
    def __print_version
      puts AiCli::VERSION
    end

    private

    def init_i18n
      config = Helpers::Config.get
      Helpers::I18n.set_language(config['LANGUAGE'])
    rescue StandardError
      Helpers::I18n.set_language('en')
    end
  end
end
