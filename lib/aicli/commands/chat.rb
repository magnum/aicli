# frozen_string_literal: true

require 'io/console'
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
        restored = Helpers::Context.load_messages
        Helpers::Context.apply_to_chat(chat) if restored.any?

        pastel = Pastel.new
        prompt = TTY::Prompt.new(interrupt: :error)
        Helpers::Context.seed_prompt_history(prompt)

        puts ''
        puts "#{config['PROVIDER']} / #{config['MODEL']}  #{pastel.dim('Ctrl+d to quit')}"

        catch(:chat_quit) do
          prompt.on(:keyctrl_d) { throw :chat_quit }

          loop do
            begin
              user_prompt = prompt.ask(pastel.cyan("#{Helpers::I18n.t('You')}:")) do |q|
                q.required true
                q.validate(/.+/, Helpers::I18n.t('Please enter a prompt.'))
              end
            rescue TTY::Reader::InputInterrupt
              # Ctrl+C clears the current input line and re-prompts.
              print "\r\e[2K"
              next
            end

            if user_prompt.nil? || user_prompt.strip.downcase == 'exit'
              throw :chat_quit
            end

            spinner = TTY::Spinner.new("[:spinner] #{Helpers::I18n.t('THINKING...')}", format: :dots)
            spinner.auto_spin
            started = false

            response = Helpers::Completion.stream_chat_message(
              chat,
              user_prompt,
              writer: lambda { |chunk|
                unless started
                  spinner.success(pastel.green('ai:'))
                  puts ''
                  started = true
                end
                print chunk
              }
            )

            unless started
              spinner.success(pastel.green('ai:'))
              puts ''
            end
            puts ''
            puts ''

            Helpers::Context.save_from_chat(chat)
            offer_to_run_commands(response, pastel)
          end
        end

        Helpers::Context.save_from_chat(chat)
        puts ''
        puts Helpers::I18n.t('Goodbye!')
      end

      def offer_to_run_commands(response, pastel)
        commands = Helpers::Completion.extract_commands(response)
        return if commands.empty?

        commands.each do |command|
          puts pastel.dim(command)
          next unless ask_to_run?

          run_command(command)
          puts ''
        end
      end

      # Only explicit `y` runs the command. Enter, Esc, n, Ctrl-C → skip.
      def ask_to_run?
        tty = File.open('/dev/tty', 'r+')
        tty.print "#{Helpers::I18n.t('Run it?')} (y/n) "
        tty.flush
        char = tty.getch
        tty.puts
        char.to_s.downcase == 'y'
      rescue Interrupt
        begin
          tty&.puts
        rescue StandardError
          puts
        end
        false
      ensure
        tty&.close
      end

      def run_command(command)
        puts "#{Helpers::I18n.t('Running')}: #{command}"
        puts ''
        system(ENV['SHELL'] || 'bash', '-c', command)
        Helpers::ShellHistory.append(command)
      end

      private_class_method :offer_to_run_commands, :ask_to_run?, :run_command
    end
  end
end
