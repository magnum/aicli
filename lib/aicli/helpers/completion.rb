# frozen_string_literal: true

module AiCli
  module Helpers
    module Completion
      EXPLAIN_IN_SECOND_REQUEST = true
      SHELL_CODE_EXCLUSIONS = [/```[a-zA-Z]*\n?/i, /```[a-zA-Z]*/i, "\n"].freeze

      module_function

      def get_script_and_info(prompt:, config:)
        {
          read_script: stream_prompt(full_prompt(prompt), config: config, exclusions: SHELL_CODE_EXCLUSIONS),
          read_info: ->(_writer) { '' }
        }
      end

      def get_explanation(script:, config:)
        { read_explanation: stream_prompt(explanation_prompt(script), config: config) }
      end

      def get_revision(prompt:, code:, config:)
        {
          read_script: stream_prompt(
            revision_prompt(prompt, code),
            config: config,
            exclusions: SHELL_CODE_EXCLUSIONS
          )
        }
      end

      def get_models(provider)
        Llm.list_chat_models(provider)
      end

      # Streams a single-turn completion. Returns a callable that takes a writer.
      def stream_prompt(prompt, config:, exclusions: [])
        lambda do |writer|
          stream_to_writer(prompt, config: config, exclusions: exclusions, writer: writer)
        end
      end

      # Multi-turn chat helper used by `aicli chat`.
      def start_chat(config)
        Llm.build_chat(config)
      end

      def stream_chat_message(chat, message, writer:)
        data = +''

        begin
          chat.ask(message) do |chunk|
            content = chunk.content.to_s
            next if content.empty?

            data << content
            writer.call(content)
          end
        rescue RubyLLM::Error, RubyLLM::ConfigurationError => e
          handle_ruby_llm_error(e)
        end

        data
      end

      def explanation_prompt(script)
        <<~PROMPT
          #{explain_script} Please reply in #{I18n.current_language_name}

          The script: #{script}
        PROMPT
      end

      def shell_details
        "The target shell is #{OsDetect.detect_shell}"
      end

      def explain_script
        'Please provide a clear, concise description of the script, using minimal words. Outline the steps in a list format.'
      end

      def generation_details
        <<~DETAILS.chomp
          Only reply with the single line command surrounded by three backticks. It must be able to be directly run in the target shell. Do not include any other text.

          Make sure the command runs on #{OsDetect.operating_system_name} operating system.
        DETAILS
      end

      def full_prompt(prompt)
        explain = EXPLAIN_IN_SECOND_REQUEST ? '' : explain_script
        <<~PROMPT
          Create a single line command that one can enter in a terminal and run, based on what is specified in the prompt.

          #{shell_details}

          #{generation_details}

          #{explain}

          The prompt is: #{prompt}
        PROMPT
      end

      def revision_prompt(prompt, code)
        <<~PROMPT
          Update the following script based on what is asked in the following prompt.

          The script: #{code}

          The prompt: #{prompt}

          #{generation_details}
        PROMPT
      end

      def stream_to_writer(prompt, config:, exclusions:, writer:)
        chat = Llm.build_chat(config)
        data = +''
        data_start = exclusions.empty?
        buffer = +''
        excluded_prefix = exclusions.first

        begin
          chat.ask(prompt) do |chunk|
            content = chunk.content.to_s
            next if content.empty?

            unless data_start
              buffer << content
              next unless excluded_prefix.nil? || buffer.match?(excluded_prefix)

              data_start = true
              remainder = StripRegexPatterns.call(buffer, exclusions)
              buffer = +''
              next if remainder.empty?

              data << remainder
              writer.call(remainder)
              next
            end

            cleaned = StripRegexPatterns.call(content, exclusions)
            next if cleaned.empty?

            data << cleaned
            writer.call(cleaned)
          end
        rescue RubyLLM::Error, RubyLLM::ConfigurationError => e
          handle_ruby_llm_error(e)
        end

        data
      end

      def handle_ruby_llm_error(error)
        message = error.message.to_s

        if error.is_a?(RubyLLM::RateLimitError) || error.is_a?(RubyLLM::PaymentRequiredError) ||
           message.match?(/rate.?limit|quota|billing/i)
          raise KnownError, <<~MSG
            Request to the LLM provider failed (rate limit / quota).

            Check your plan and billing details for the configured provider, then try again.

            Full message:

            #{message}
          MSG
        end

        if message.match?(/model_not_found|does not exist|do not have access/i)
          raise KnownError, <<~MSG
            The configured model is not available for this API key/provider.

            Fix with:
              #{Constants::COMMAND_NAME} config
            or:
              #{Constants::COMMAND_NAME} config set MODEL=#{Llm.default_model_for('anthropic')}
              #{Constants::COMMAND_NAME} config set PROVIDER=anthropic

            Full message:

            #{message}
          MSG
        end

        raise KnownError, <<~MSG
          Request to the LLM provider failed:

          #{message}
        MSG
      end
      private_class_method :stream_to_writer, :handle_ruby_llm_error
    end
  end
end
