# frozen_string_literal: true

require 'yaml'

module AiShell
  module Helpers
    module I18n
      LANGUAGES = {
        'en' => 'English',
        'zh-Hans' => '简体中文',
        'zh-Hant' => '繁體中文',
        'es' => 'Español',
        'jp' => '日本語',
        'ko' => '한국어',
        'fr' => 'Français',
        'de' => 'Deutsch',
        'ru' => 'Русский',
        'uk' => 'Українська',
        'vi' => 'Tiếng Việt',
        'ar' => 'العربية',
        'pt' => 'Português',
        'id' => 'Indonesia',
        'it' => 'Italiano',
        'tr' => 'Türkçe'
      }.freeze

      class << self
        attr_reader :current_lang

        def set_language(lang)
          @current_lang = lang.nil? || lang.empty? ? 'en' : lang
          load_translations
        end

        def t(key)
          return key if @current_lang.nil? || @current_lang == 'en'

          @translations[key] || key
        end

        def current_language_name
          LANGUAGES[@current_lang] || LANGUAGES['en']
        end

        def languages
          LANGUAGES
        end

        private

        def load_translations
          return if @current_lang == 'en'

          locale_path = File.expand_path(
            "../../../locales/#{@current_lang}.yml",
            __dir__
          )

          @translations = if File.exist?(locale_path)
                            YAML.safe_load(File.read(locale_path), permitted_classes: [String]) || {}
                          else
                            {}
                          end
        end
      end

      set_language('en')
    end
  end
end
