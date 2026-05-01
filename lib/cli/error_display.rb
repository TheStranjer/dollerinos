# frozen_string_literal: true

module Cli
  # Renders a service error to stdout with a coloured header.
  class ErrorDisplay
    def initialize(palette)
      @palette = palette
    end

    def render(message)
      puts
      puts @palette[:error].render('❌ Error')
      puts
      puts message
      puts
    end
  end
end
