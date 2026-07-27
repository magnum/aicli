# frozen_string_literal: true

require 'pastel'
require 'tty-prompt'
require 'tty-spinner'

module AiCli
  module Commands
    module Chat
      module_function

      def run
        config = Helpers::Config.get
        chat = Helpers::Completion.start_chat(config)

        pastel = Pastel.new
        prompt = TTY::Prompt.new(interrupt: :exit)
        confirm = TTY::Prompt.new(interrupt: :exit, track_history: false)

        puts ''
        puts "┌  #{Helpers::I18n.t('Starting new conversation')}"
        puts pastel.dim("   #{config['PROVIDER']} / #{config['MODEL']}")
        puts pastel.dim("   #{Helpers::I18n.t('Ask for a shell command. Type exit to quit.')}")

        loop do
          user_prompt = prompt.ask(pastel.cyan("#{Helpers::I18n.t('You')}:")) do |q|
            q.required true
            q.validate(/.+/, Helpers::I18n.t('Please enter a prompt.'))
          end

          if user_prompt.nil? || user_prompt.strip.downcase == 'exit'
            puts "└  #{Helpers::I18n.t('Goodbye!')}"
            break
          end

          spinner = TTY::Spinner.new("[:spinner] #{Helpers::I18n.t('THINKING...')}", format: :dots)
          spinner.auto_spin
          started = false

          response = Helpers::Completion.stream_chat_message(
            chat,
            user_prompt,
            writer: lambda { |chunk|
              unless started
                spinner.success(pastel.green('aicli:'))
                puts ''
                started = true
              end
              print chunk
            }
          )

          unless started
            spinner.success(pastel.green('aicli:'))
            puts ''
          end
          puts ''
          puts ''

          offer_to_run_commands(response, confirm, pastel)
        end
      end

      def offer_to_run_commands(response, confirm, pastel)
        commands = Helpers::Completion.extract_commands(response)
        return if commands.empty?

        commands.each do |command|
          puts pastel.dim("• #{command}")
          next unless confirm.yes?(Helpers::I18n.t('Run this script?'), default: true)

          run_command(command)
          puts ''
        end
      end

      def run_command(command)
        puts "└  #{Helpers::I18n.t('Running')}: #{command}"
        puts ''
        system(ENV['SHELL'] || 'bash', '-c', command)
        Helpers::ShellHistory.append(command)
      end

      private_class_method :offer_to_run_commands, :run_command
    end
  end
end
