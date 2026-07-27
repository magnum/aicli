# frozen_string_literal: true

require 'pastel'

module AiShell
  module Commands
    module Config
      module_function

      def run(mode = nil, *key_values)
        pastel = Pastel.new

        if mode.nil? || mode == 'ui'
          Helpers::Config.show_config_ui
          return
        end

        if key_values.empty?
          puts "#{Helpers::I18n.t('Error')}: #{Helpers::I18n.t('Missing required parameter')} \"key=value\"\n"
          exit 1
        end

        case mode
        when 'get'
          config = Helpers::Config.get
          key_values.each do |key|
            if Helpers::Config.has_own?(config, key)
              puts "#{key}=#{config[key]}"
            else
              raise Helpers::KnownError, "#{Helpers::I18n.t('Invalid config property')}: #{key}"
            end
          end
        when 'set'
          pairs = key_values.map do |kv|
            k, v = kv.split('=', 2)
            [k, v]
          end
          Helpers::Config.set(pairs)
        else
          raise Helpers::KnownError, "#{Helpers::I18n.t('Invalid mode')}: #{mode}"
        end
      rescue Helpers::KnownError, StandardError => e
        puts "\n#{pastel.red('✖')} #{e.message}"
        Helpers::Error.handle_cli_error(e)
        exit 1
      end
    end
  end
end
