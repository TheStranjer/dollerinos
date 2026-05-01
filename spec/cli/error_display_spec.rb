# frozen_string_literal: true

require_relative '../../lib/cli/error_display'
require_relative '../../lib/cli/styles'

describe Cli::ErrorDisplay do
  let(:palette) { Cli::Styles.palette }

  def render(message)
    output = StringIO.new
    $stdout = output
    described_class.new(palette).render(message)
    output.string
  ensure
    $stdout = STDOUT
  end

  it 'shows an Error header and the message body' do
    rendered = render('boom')
    expect(rendered).to include('Error').and include('boom')
  end
end
