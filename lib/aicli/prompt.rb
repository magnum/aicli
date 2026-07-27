# frozen_string_literal: true

require 'open3'
require 'clipboard'
require 'pastel'
require 'tty-prompt'
require 'tty-spinner'

module AiCli
  module Prompt
    module_function

    def run(use_prompt: nil, silent_mode: false)
      init_i18n

      config = Helpers::Config.get
      skip_explanation = silent_mode || config['SILENT_MODE']

      pastel = Pastel.new
      puts ''
      puts "┌  #{pastel.cyan(Helpers::Constants::PROJECT_NAME)}"

      the_prompt = use_prompt.nil? || use_prompt.strip.empty? ? ask_prompt : use_prompt

      spinner = TTY::Spinner.new("[:spinner] #{Helpers::I18n.t('Loading...')}", format: :dots)
      spinner.auto_spin

      result = Helpers::Completion.get_script_and_info(
        prompt: the_prompt,
        config: config
      )

      spinner.success(Helpers::I18n.t('Your script') + ':')
      puts ''
      script = result[:read_script].call(->(chunk) { print chunk })
      puts ''
      puts ''
      puts pastel.dim('•')

      unless skip_explanation
        spinner = TTY::Spinner.new("[:spinner] #{Helpers::I18n.t('Getting explanation...')}", format: :dots)
        spinner.auto_spin

        info = result[:read_info].call(->(chunk) { print chunk })
        if info.nil? || info.empty?
          explanation = Helpers::Completion.get_explanation(
            script: script,
            config: config
          )
          spinner.success(Helpers::I18n.t('Explanation') + ':')
          puts ''
          explanation[:read_explanation].call(->(chunk) { print chunk })
          puts ''
          puts ''
          puts pastel.dim('•')
        else
          spinner.success(Helpers::I18n.t('Explanation') + ':')
        end
      end

      run_or_revise_flow(script, config, silent_mode)
    end

    def init_i18n
      config = Helpers::Config.get
      Helpers::I18n.set_language(config['LANGUAGE'])
    rescue StandardError
      Helpers::I18n.set_language('en')
    end

    def examples
      [
        Helpers::I18n.t('delete all log files'),
        Helpers::I18n.t('list js files'),
        Helpers::I18n.t('fetch me a random joke'),
        Helpers::I18n.t('list all commits')
      ]
    end

    def ask_prompt(initial = nil)
      prompt = TTY::Prompt.new(interrupt: :exit)
      prompt.ask(Helpers::I18n.t('What would you like me to do?')) do |q|
        q.required true
        q.default initial || Helpers::I18n.t('Say hello')
        q.validate(/.+/, Helpers::I18n.t('Please enter a prompt.'))
      end
    end

    def ask_revision
      prompt = TTY::Prompt.new(interrupt: :exit)
      prompt.ask(Helpers::I18n.t('What would you like me to change in this script?')) do |q|
        q.required true
        q.validate(/.+/, Helpers::I18n.t('Please enter a prompt.'))
      end
    end

    def run_script(script)
      puts "└  #{Helpers::I18n.t('Running')}: #{script}"
      puts ''
      system(ENV['SHELL'] || 'bash', '-c', script)
      Helpers::ShellHistory.append(script)
    end

    def run_or_revise_flow(script, config, silent_mode)
      prompt = TTY::Prompt.new(interrupt: :exit)
      empty_script = script.strip.empty?

      choices = []
      unless empty_script
        choices << { name: "✅ #{Helpers::I18n.t('Yes')}", value: :yes }
        choices << { name: "📝 #{Helpers::I18n.t('Edit')}", value: :edit }
      end
      choices << { name: "🔁 #{Helpers::I18n.t('Revise')}", value: :revise }
      choices << { name: "📋 #{Helpers::I18n.t('Copy')}", value: :copy }
      choices << { name: "❌ #{Helpers::I18n.t('Cancel')}", value: :cancel }

      message = empty_script ? Helpers::I18n.t('Revise this script?') : Helpers::I18n.t('Run this script?')
      answer = prompt.select(message, choices)

      case answer
      when :yes
        run_script(script)
      when :edit
        new_script = prompt.ask(Helpers::I18n.t('you can edit script here'), default: script)
        run_script(new_script) if new_script && !new_script.empty?
      when :revise
        revision_flow(script, config, silent_mode)
      when :copy
        Clipboard.copy(script)
        puts "└  #{Helpers::I18n.t('Copied to clipboard!')}"
      when :cancel
        puts "└  #{Helpers::I18n.t('Goodbye!')}"
        exit 0
      end
    end

    def revision_flow(current_script, config, silent_mode)
      pastel = Pastel.new
      revision = ask_revision

      spinner = TTY::Spinner.new("[:spinner] #{Helpers::I18n.t('Loading...')}", format: :dots)
      spinner.auto_spin

      result = Helpers::Completion.get_revision(
        prompt: revision,
        code: current_script,
        config: config
      )

      spinner.success(Helpers::I18n.t('Your new script') + ':')
      puts ''
      script = result[:read_script].call(->(chunk) { print chunk })
      puts ''
      puts ''
      puts pastel.dim('•')

      unless silent_mode
        info_spinner = TTY::Spinner.new("[:spinner] #{Helpers::I18n.t('Getting explanation...')}", format: :dots)
        info_spinner.auto_spin

        explanation = Helpers::Completion.get_explanation(
          script: script,
          config: config
        )

        info_spinner.success(Helpers::I18n.t('Explanation') + ':')
        puts ''
        explanation[:read_explanation].call(->(chunk) { print chunk })
        puts ''
        puts ''
        puts pastel.dim('•')
      end

      run_or_revise_flow(script, config, silent_mode)
    end

    private_class_method :init_i18n, :examples, :ask_prompt, :ask_revision,
                         :run_script, :run_or_revise_flow, :revision_flow
  end
end
