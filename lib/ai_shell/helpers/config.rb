# frozen_string_literal: true

require 'fileutils'
require 'pastel'
require 'tty-prompt'

module AiShell
  module Helpers
    module Config
      CONFIG_PATH = File.join(Dir.home, '.ai-shell')

      CONFIG_PARSERS = {
        'OPENAI_KEY' => lambda { |key|
          if key.nil? || key.empty?
            raise KnownError,
                  "Please set your OpenAI API key via `#{Constants::COMMAND_NAME} config set OPENAI_KEY=<your token>`"
          end
          key
        },
        'MODEL' => lambda { |model|
          model.nil? || model.empty? ? 'gpt-4o-mini' : model
        },
        'SILENT_MODE' => lambda { |mode|
          mode.to_s.downcase == 'true'
        },
        'OPENAI_API_ENDPOINT' => lambda { |api_endpoint|
          api_endpoint.nil? || api_endpoint.empty? ? 'https://api.openai.com/v1' : api_endpoint
        },
        'LANGUAGE' => lambda { |language|
          language.nil? || language.empty? ? 'en' : language
        }
      }.freeze

      module_function

      def get(cli_config = nil)
        config = read_config_file
        parsed = {}

        CONFIG_PARSERS.each do |key, parser|
          value = cli_config&.dig(key) || config[key]
          parsed[key] = parser.call(value)
        end

        parsed
      end

      def set(key_values)
        config = read_config_file

        key_values.each do |key, value|
          unless CONFIG_PARSERS.key?(key)
            raise KnownError, "#{I18n.t('Invalid config property')}: #{key}"
          end

          parsed = CONFIG_PARSERS[key].call(value)
          config[key] = parsed.to_s
        end

        File.write(CONFIG_PATH, stringify_ini(config))
      end

      def has_own?(object, key)
        object.key?(key)
      end

      def show_config_ui
        pastel = Pastel.new
        prompt = TTY::Prompt.new(interrupt: :exit)

        loop do
          config = get
          choice = prompt.select("#{I18n.t('Set config')}:") do |menu|
            menu.choice "#{I18n.t('OpenAI Key')} (#{display_hint(config, 'OPENAI_KEY') { |v| "sk-...#{v[-3..]}" }})",
                        'OPENAI_KEY'
            menu.choice "#{I18n.t('OpenAI API Endpoint')} (#{display_hint(config, 'OPENAI_API_ENDPOINT')})",
                        'OPENAI_API_ENDPOINT'
            menu.choice "#{I18n.t('Silent Mode')} (#{display_hint(config, 'SILENT_MODE')})",
                        'SILENT_MODE'
            menu.choice "#{I18n.t('Model')} (#{display_hint(config, 'MODEL')})",
                        'MODEL'
            menu.choice "#{I18n.t('Language')} (#{display_hint(config, 'LANGUAGE')})",
                        'LANGUAGE'
            menu.choice I18n.t('Cancel'), 'cancel'
          end

          case choice
          when 'OPENAI_KEY'
            key = prompt.ask(I18n.t('Enter your OpenAI API key')) do |q|
              q.required true
            end
            set([['OPENAI_KEY', key]])
          when 'OPENAI_API_ENDPOINT'
            api_endpoint = prompt.ask(I18n.t('Enter your OpenAI API Endpoint'))
            set([['OPENAI_API_ENDPOINT', api_endpoint]]) if api_endpoint
          when 'SILENT_MODE'
            silent = prompt.yes?(I18n.t('Enable silent mode?'))
            set([['SILENT_MODE', silent ? 'true' : 'false']])
          when 'MODEL'
            cfg = get
            models = Completion.get_models(cfg['OPENAI_KEY'], cfg['OPENAI_API_ENDPOINT'])
            model = prompt.select('Pick a model.') do |menu|
              models.each { |m| menu.choice m['id'], m['id'] }
            end
            set([['MODEL', model]])
          when 'LANGUAGE'
            language = prompt.select(I18n.t('Enter the language you want to use')) do |menu|
              I18n.languages.each { |k, v| menu.choice v, k }
            end
            set([['LANGUAGE', language]])
            I18n.set_language(language)
          when 'cancel'
            break
          end
        end
      rescue KnownError, StandardError => e
        puts "\n#{pastel.red('✖')} #{e.message}"
        Error.handle_cli_error(e)
        exit 1
      end

      def read_config_file
        return {} unless File.exist?(CONFIG_PATH)

        parse_ini(File.read(CONFIG_PATH))
      end

      def parse_ini(content)
        result = {}
        content.each_line do |line|
          line = line.strip
          next if line.empty? || line.start_with?('#', ';')
          next unless line.include?('=')

          key, value = line.split('=', 2)
          result[key.strip] = value.strip.gsub(/\A["']|["']\z/, '')
        end
        result
      end

      def stringify_ini(config)
        "#{config.map { |k, v| "#{k}=#{v}" }.join("\n")}\n"
      end

      def display_hint(config, key)
        if config.key?(key) && !config[key].nil?
          value = config[key]
          block_given? ? yield(value) : value.to_s
        else
          I18n.t('(not set)')
        end
      end
    end
  end
end
