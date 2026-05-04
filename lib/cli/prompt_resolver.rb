# frozen_string_literal: true

module Cli
  # Resolves a user-supplied prompt for the LLM from the DOLLERINOS_PROMPT
  # environment variable, falling back to an interactive stdin prompt.
  module PromptResolver
    ENV_VAR = 'DOLLERINOS_PROMPT'
    REQUEST_MESSAGE = 'Enter a prompt for the LLM (leave blank to skip): '

    module_function

    def resolve(env: ENV, input: $stdin, output: $stdout)
      from_env = blank_to_nil(env[ENV_VAR])
      return from_env if from_env

      blank_to_nil(read_from_user(input, output))
    end

    def blank_to_nil(value)
      return nil if value.nil?

      stripped = value.to_s.strip
      stripped.empty? ? nil : stripped
    end

    def read_from_user(input, output)
      output.print(REQUEST_MESSAGE)
      output.flush if output.respond_to?(:flush)
      input.gets
    end
  end
end
