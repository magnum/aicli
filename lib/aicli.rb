# frozen_string_literal: true

require_relative 'aicli/version'
require_relative 'aicli/helpers/constants'
require_relative 'aicli/helpers/error'
require_relative 'aicli/helpers/i18n'
require_relative 'aicli/helpers/os_detect'
require_relative 'aicli/helpers/strip_regex_patterns'
require_relative 'aicli/helpers/shell_history'
require_relative 'aicli/helpers/completion'
require_relative 'aicli/helpers/config'
require_relative 'aicli/prompt'
require_relative 'aicli/commands/chat'
require_relative 'aicli/commands/config'
require_relative 'aicli/commands/update'
require_relative 'aicli/cli'

module AiCli
end
