# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'thread'

module AiCli
  module Helpers
    module Completion
      EXPLAIN_IN_SECOND_REQUEST = true
      SHELL_CODE_EXCLUSIONS = [/```[a-zA-Z]*\n/i, /```[a-zA-Z]*/i, "\n"].freeze

      module_function

      def get_script_and_info(prompt:, key:, api_endpoint:, model: nil)
        stream = generate_completion(
          prompt: full_prompt(prompt),
          key: key,
          model: model,
          api_endpoint: api_endpoint
        )
        enumerator = stream.each

        {
          read_script: read_data(enumerator, *SHELL_CODE_EXCLUSIONS),
          read_info: read_data(enumerator, *SHELL_CODE_EXCLUSIONS)
        }
      end

      def get_explanation(script:, key:, api_endpoint:, model: nil)
        stream = generate_completion(
          prompt: explanation_prompt(script),
          key: key,
          model: model,
          api_endpoint: api_endpoint
        )
        { read_explanation: read_data(stream.each) }
      end

      def get_revision(prompt:, code:, key:, api_endpoint:, model: nil)
        stream = generate_completion(
          prompt: revision_prompt(prompt, code),
          key: key,
          model: model,
          api_endpoint: api_endpoint
        )
        { read_script: read_data(stream.each, *SHELL_CODE_EXCLUSIONS) }
      end

      def get_models(key, api_endpoint)
        uri = URI.join(ensure_trailing_slash(api_endpoint), 'models')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{key}"
        request['Content-Type'] = 'application/json'

        response = http.request(request)
        raise KnownError, "Failed to list models: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        data = JSON.parse(response.body)
        data.fetch('data', []).select { |m| m['object'] == 'model' }
      end

      # Returns a live Enumerator of SSE "data: ..." lines
      def generate_completion(prompt:, key:, api_endpoint:, model: nil, number: 1)
        messages = if prompt.is_a?(Array)
                     prompt
                   else
                     [{ 'role' => 'user', 'content' => prompt }]
                   end

        uri = URI.join(ensure_trailing_slash(api_endpoint), 'chat/completions')
        body = {
          model: model || 'gpt-4o-mini',
          messages: messages,
          n: [number, 10].min,
          stream: true
        }

        queue = Queue.new
        error_box = []

        Thread.new do
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 120

          request = Net::HTTP::Post.new(uri)
          request['Authorization'] = "Bearer #{key}"
          request['Content-Type'] = 'application/json'
          request['Accept'] = 'text/event-stream'
          request.body = JSON.generate(body)

          http.request(request) do |response|
            unless response.is_a?(Net::HTTPSuccess)
              error_box << [:api, response.code.to_i, response.body]
              queue << :done
              next
            end

            buffer = +''
            response.read_body do |chunk|
              buffer << chunk
              while (eol = buffer.index("\n"))
                line = buffer.slice!(0..eol).strip
                queue << line if line.start_with?('data: ')
              end
            end
          end
          queue << :done
        rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
          error_box << [:network, uri.host, e.message]
          queue << :done
        rescue StandardError => e
          error_box << [:other, e]
          queue << :done
        end

        Enumerator.new do |yielder|
          loop do
            item = queue.pop
            break if item == :done

            yielder << item
          end

          if (err = error_box.first)
            case err[0]
            when :api
              handle_api_error(err[1], err[2])
            when :network
              raise KnownError,
                    "Error connecting to #{err[1]}. Are you connected to the internet? (#{err[2]})"
            when :other
              raise err[1]
            end
          end
        end
      end

      def read_data(enumerator, *excluded)
        lambda do |writer|
          data = +''
          data_start = false
          buffer = +''
          excluded_prefix = excluded.first

          loop do
            chunk = enumerator.next
            payloads = chunk.to_s.split("\n\n")

            payloads.each do |payload|
              return data if payload.include?('[DONE]')

              next unless payload.start_with?('data:')

              content = parse_content(payload)

              unless data_start
                buffer << content
                if excluded_prefix.nil? || buffer.match?(excluded_prefix)
                  data_start = true
                  buffer = +''
                  break if excluded_prefix
                end
              end

              next unless data_start && !content.empty?

              cleaned = StripRegexPatterns.call(content, excluded)
              data << cleaned
              writer.call(cleaned)
            end
          rescue StopIteration
            break
          end

          data
        end
      end

      def parse_content(payload)
        raw = payload.sub(/^data:\s*/, '')
        delta = JSON.parse(raw.strip)
        delta.dig('choices', 0, 'delta', 'content') || ''
      rescue JSON::ParserError => e
        "Error with JSON.parse and #{payload}.\n#{e}"
      end

      def handle_api_error(status, body)
        message_string = begin
          JSON.pretty_generate(JSON.parse(body))
        rescue StandardError
          body.to_s
        end

        if status == 429
          raise KnownError, <<~MSG
            Request to OpenAI failed with status 429. This is due to incorrect billing setup or excessive quota usage. Please follow this guide to fix it: https://help.openai.com/en/articles/6891831-error-code-429-you-exceeded-your-current-quota-please-check-your-plan-and-billing-details

            You can activate billing here: https://platform.openai.com/account/billing/overview . Make sure to add a payment method if not under an active grant from OpenAI.

            Full message from OpenAI:

            #{message_string}
          MSG
        end

        raise KnownError, <<~MSG
          Request to OpenAI failed with status #{status}:

          #{message_string}
        MSG
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

      def ensure_trailing_slash(endpoint)
        endpoint.end_with?('/') ? endpoint : "#{endpoint}/"
      end
    end
  end
end
