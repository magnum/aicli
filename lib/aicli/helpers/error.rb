# frozen_string_literal: true

require 'pastel'

module AiCli
  module Helpers
    class KnownError < StandardError; end

    module Error
      module_function

      def handle_cli_error(error)
        return if error.is_a?(KnownError)

        pastel = Pastel.new
        indent = ' ' * 4

        if error.is_a?(StandardError) && error.backtrace
          puts pastel.dim(error.backtrace.join("\n"))
        end

        puts "\n#{indent}#{pastel.dim("aicli v#{AiCli::VERSION}")}"
        puts "\n#{indent}#{I18n.t('Please open a Bug report with the information above')}:"
        puts "#{indent}https://github.com/magnum/aicli/issues/new"
      end
    end
  end
end
