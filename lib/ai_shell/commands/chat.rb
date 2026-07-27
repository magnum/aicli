# frozen_string_literal: true

require 'pastel'
require 'tty-prompt'
require 'tty-spinner'

module AiShell
  module Commands
    module Chat
      module_function

      def run
        config = Helpers::Config.get
        key = config['OPENAI_KEY']
        model = config['MODEL']
        api_endpoint = config['OPENAI_API_ENDPOINT']
        chat_history = []

        pastel = Pastel.new
        prompt = TTY::Prompt.new(interrupt: :exit)

        puts ''
        puts "┌  #{Helpers::I18n.t('Starting new conversation')}"

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

          chat_history << { 'role' => 'user', 'content' => user_prompt }

          stream_lines = Helpers::Completion.generate_completion(
            prompt: chat_history,
            key: key,
            model: model,
            api_endpoint: api_endpoint
          )
          enumerator = stream_lines.each
          read_response = Helpers::Completion.read_data(enumerator)

          spinner.success(pastel.green('AI Shell:'))
          puts ''
          full_response = read_response.call(->(chunk) { print chunk })
          chat_history << { 'role' => 'assistant', 'content' => full_response }
          puts ''
          puts ''
        end
      end
    end
  end
end
