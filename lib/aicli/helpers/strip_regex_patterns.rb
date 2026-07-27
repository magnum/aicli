# frozen_string_literal: true

module AiCli
  module Helpers
    module StripRegexPatterns
      module_function

      def call(input_string, pattern_list)
        pattern_list.reduce(input_string) do |current, pattern|
          next current if pattern.nil?

          if pattern.is_a?(Regexp)
            current.gsub(pattern, '')
          else
            current.gsub(pattern.to_s, '')
          end
        end
      end
    end
  end
end
