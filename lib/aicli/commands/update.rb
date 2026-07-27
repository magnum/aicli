# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'pastel'

module AiCli
  module Commands
    module Update
      RUBYGEMS_GEM_URI = 'https://rubygems.org/api/v1/gems/aicli.json'

      module_function

      def run
        pastel = Pastel.new
        current = Gem::Version.new(AiCli::VERSION)

        puts ''
        puts pastel.dim("Current version: #{current}")

        latest_str = fetch_latest_version
        latest = Gem::Version.new(latest_str)
        puts pastel.dim("Latest on RubyGems: #{latest}")
        puts ''

        if latest < current
          puts pastel.yellow(
            "Installed #{current} is newer than RubyGems #{latest}. Skipping update."
          )
          puts pastel.dim('Publish a new version, then run `ai update` again.')
          return
        end

        if latest == current
          puts pastel.green("Already up to date (#{current}).")
          return
        end

        command = ['gem', 'install', 'aicli', '-v', latest_str]
        puts pastel.dim("#{Helpers::I18n.t('Running')}: #{command.join(' ')}")
        puts ''

        ok = system(*command)
        puts ''

        unless ok
          raise Helpers::KnownError,
                'Failed to update aicli. Try manually: gem install aicli'
        end

        puts pastel.green("Updated aicli to #{latest}.")
        puts pastel.dim('Open a new shell if `ai version` still shows the old number.')
      rescue Helpers::KnownError => e
        puts "\n#{pastel.red('✖')} #{e.message}"
        exit 1
      rescue StandardError => e
        puts "\n#{pastel.red('✖')} Could not check RubyGems for updates: #{e.message}"
        Helpers::Error.handle_cli_error(e)
        exit 1
      end

      def fetch_latest_version
        uri = URI(RUBYGEMS_GEM_URI)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.open_timeout = 10
          http.read_timeout = 10
          http.get(uri.request_uri)
        end

        unless response.is_a?(Net::HTTPSuccess)
          raise "RubyGems returned HTTP #{response.code}"
        end

        version = JSON.parse(response.body)['version'].to_s
        raise 'RubyGems response missing version' if version.empty?

        version
      end
      private_class_method :fetch_latest_version
    end
  end
end
