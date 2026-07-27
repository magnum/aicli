# frozen_string_literal: true

module AiShell
  module Helpers
    module ShellHistory
      module_function

      def append(command)
        history_file = history_file_path
        return unless history_file

        last = last_command(history_file)
        return if last == command

        File.open(history_file, 'a') { |f| f.puts(command) }
      rescue StandardError
        # Ignore history write errors
      end

      def history_file_path
        shell = File.basename(ENV['SHELL'] || '')
        home = Dir.home

        case shell
        when 'bash', 'sh'
          File.join(home, '.bash_history')
        when 'zsh'
          File.join(home, '.zsh_history')
        when 'fish'
          File.join(home, '.local', 'share', 'fish', 'fish_history')
        when 'ksh'
          File.join(home, '.ksh_history')
        when 'tcsh'
          File.join(home, '.history')
        end
      end

      def last_command(history_file)
        return nil unless File.exist?(history_file)

        lines = File.read(history_file).strip.split("\n")
        lines.last
      rescue StandardError
        nil
      end
    end
  end
end
