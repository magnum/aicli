# frozen_string_literal: true

require 'pastel'

module AiCli
  module Commands
    module Update
      module_function

      def run
        pastel = Pastel.new
        puts ''
        command = 'gem update aicli'
        puts pastel.dim("#{Helpers::I18n.t('Running')}: #{command}")
        puts ''
        system(command)
        puts ''
      end
    end
  end
end
