# frozen_string_literal: true

require 'etc'
require 'rbconfig'

module AiCli
  module Helpers
    module OsDetect
      module_function

      def detect_shell
        return 'powershell' if RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)

        shell = ENV['SHELL'] || Etc.getpwuid.shell || 'bash'
        File.basename(shell)
      rescue StandardError => e
        raise "#{I18n.t('Shell detection failed unexpectedly')}: #{e.message}"
      end

      def operating_system_name
        case RbConfig::CONFIG['host_os']
        when /mswin|mingw|cygwin/i then 'Windows'
        when /darwin/i then 'macOS'
        when /linux/i then 'Linux'
        when /bsd/i then 'BSD'
        else RbConfig::CONFIG['host_os']
        end
      end
    end
  end
end
