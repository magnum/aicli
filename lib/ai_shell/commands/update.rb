# frozen_string_literal: true

require 'pastel'

module AiShell
  module Commands
    module Update
      module_function

      def run
        pastel = Pastel.new
        puts ''
        command = 'gem update ai-shell'
        puts pastel.dim("#{Helpers::I18n.t('Running')}: #{command}")
        puts ''
        system(command)
        puts ''
      end
    end
  end
end
