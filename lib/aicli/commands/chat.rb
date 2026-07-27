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

        puts ''
        puts "┌  #{Helpers::I18n.t('Starting new conversation')}"
        puts pastel.dim("   #{config['PROVIDER']} / #{config['MODEL']}")

        loop do
          user_prompt = prompt.ask(pastel.cyan("#{Helpers::I18n.t('You')}:")) do |q|
            q.required true
            q.validate(/.+/, Helpers::I18n.t('Please enter a prompt.'))
          end

          if user_prompt.nil? || user_prompt == 'exit'
            puts "└  #{Helpers::I18n.t('Goodbye!')}"
            exit 0
          end

          spinner = TTY::Spinner.new("[:spinner] #{Helpers::I18n.t('THINKING...')}", format: :dots)
          spinner.auto_spin
          started = false

          Helpers::Completion.stream_chat_message(
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
        end
      end
    end
  end
end
