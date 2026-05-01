# frozen_string_literal: true

# Captures everything written to $stdout while the block runs.
module StdoutCapture
  def capture_stdout
    output = StringIO.new
    original = $stdout
    $stdout = output
    yield
    output.string
  ensure
    $stdout = original
  end
end
