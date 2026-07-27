# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

module AiCli
  module Helpers
    module Context
      # Keep the last N user/assistant messages across sessions.
      MAX_MESSAGES = 40
      CONTEXT_FILENAME = 'context'

      module_function

      def path
        File.join(Config.home_dir, CONTEXT_FILENAME)
      end

      def load_messages
        Config.ensure_home!
        return [] unless File.file?(path)

        data = JSON.parse(File.read(path))
        Array(data['messages'])
          .select { |m| m.is_a?(Hash) && %w[user assistant].include?(m['role'].to_s) }
          .map { |m| { 'role' => m['role'].to_s, 'content' => m['content'].to_s } }
          .reject { |m| m['content'].strip.empty? }
          .last(MAX_MESSAGES)
      rescue StandardError
        []
      end

      def save_messages(messages)
        Config.ensure_home!
        normalized = Array(messages)
                     .map { |m| normalize_message(m) }
                     .compact
                     .last(MAX_MESSAGES)

        payload = {
          'version' => 1,
          'updated_at' => Time.now.utc.iso8601,
          'messages' => normalized
        }
        File.write(path, "#{JSON.pretty_generate(payload)}\n")
      rescue StandardError
        # Ignore persistence failures; chat should still work.
      end

      def save_from_chat(chat)
        save_messages(chat.messages)
      end

      def apply_to_chat(chat)
        load_messages.each do |message|
          chat.add_message(role: message['role'].to_sym, content: message['content'])
        end
      end

      def user_prompts
        load_messages.select { |m| m['role'] == 'user' }.map { |m| m['content'] }
      end

      def seed_prompt_history(prompt)
        return unless prompt.respond_to?(:reader)

        user_prompts.each do |line|
          prompt.reader.add_to_history(line)
        end
      rescue StandardError
        nil
      end

      def normalize_message(message)
        if message.respond_to?(:role) && message.respond_to?(:content)
          role = message.role.to_s
          content = message.content.to_s
        elsif message.is_a?(Hash)
          role = (message[:role] || message['role']).to_s
          content = (message[:content] || message['content']).to_s
        else
          return nil
        end

        return nil unless %w[user assistant].include?(role)
        return nil if content.strip.empty?

        { 'role' => role, 'content' => content }
      end
      private_class_method :normalize_message
    end
  end
end
