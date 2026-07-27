# frozen_string_literal: true

require_relative 'ai_shell/version'
require_relative 'ai_shell/helpers/constants'
require_relative 'ai_shell/helpers/error'
require_relative 'ai_shell/helpers/i18n'
require_relative 'ai_shell/helpers/os_detect'
require_relative 'ai_shell/helpers/strip_regex_patterns'
require_relative 'ai_shell/helpers/shell_history'
require_relative 'ai_shell/helpers/completion'
require_relative 'ai_shell/helpers/config'
require_relative 'ai_shell/prompt'
require_relative 'ai_shell/commands/chat'
require_relative 'ai_shell/commands/config'
require_relative 'ai_shell/commands/update'
require_relative 'ai_shell/cli'

module AiShell
end
