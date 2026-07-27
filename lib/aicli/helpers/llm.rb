# frozen_string_literal: true

require 'ruby_llm'

module AiCli
  module Helpers
    module Llm
      PROVIDERS = %w[openai anthropic].freeze

      DEFAULT_MODELS = {
        'openai' => 'gpt-4o-mini',
        'anthropic' => 'claude-sonnet-4-6'
      }.freeze

      module_function

      def configure!(config)
        provider = normalize_provider(config['PROVIDER'])
        ensure_credentials!(config, provider)

        RubyLLM.configure do |c|
          openai_key = config['OPENAI_KEY'].to_s
          anthropic_key = config['ANTHROPIC_KEY'].to_s
          endpoint = config['OPENAI_API_ENDPOINT'].to_s

          c.openai_api_key = openai_key unless openai_key.empty?
          c.anthropic_api_key = anthropic_key unless anthropic_key.empty?

          if !endpoint.empty? && endpoint != 'https://api.openai.com/v1'
            c.openai_api_base = endpoint.sub(%r{/+\z}, '')
          end
        end

        provider
      end

      def build_chat(config)
        provider = configure!(config)
        model = config['MODEL'].to_s
        model = default_model_for(provider) if model.empty?

        opts = { model: model, provider: provider.to_sym }
        opts[:assume_model_exists] = true unless model_known?(model, provider)
        RubyLLM.chat(**opts)
      end

      def list_chat_models(provider)
        provider = normalize_provider(provider)

        RubyLLM.models.chat_models
               .by_provider(provider.to_sym)
               .select { |m| text_chat_model?(m) }
               .sort_by { |m| [m.name.to_s.downcase, m.id] }
               .map { |m| { 'id' => m.id, 'name' => m.name.to_s } }
      end

      def default_model_for(provider)
        DEFAULT_MODELS.fetch(normalize_provider(provider), DEFAULT_MODELS['openai'])
      end

      def normalize_provider(provider)
        value = provider.to_s.downcase
        PROVIDERS.include?(value) ? value : 'openai'
      end

      def ensure_credentials!(config, provider = nil)
        provider = normalize_provider(provider || config['PROVIDER'])

        case provider
        when 'anthropic'
          if config['ANTHROPIC_KEY'].to_s.empty?
            raise KnownError,
                  "Please set your Anthropic API key via `#{Constants::COMMAND_NAME} config set ANTHROPIC_KEY=<your token>`"
          end
        else
          if config['OPENAI_KEY'].to_s.empty?
            raise KnownError,
                  "Please set your OpenAI API key via `#{Constants::COMMAND_NAME} config set OPENAI_KEY=<your token>`"
          end
        end
      end

      def model_known?(model, provider)
        RubyLLM.models.find(model, provider.to_sym)
        true
      rescue StandardError
        false
      end

      def text_chat_model?(model)
        outputs = Array(model.modalities&.output).map(&:to_s)
        return false unless outputs.include?('text')

        !model.id.match?(/tts|transcribe|realtime|whisper|embedding|moderation|dall-e|imagen|search-preview|babbage|davinci|ada-|curie/i)
      end
    end
  end
end
