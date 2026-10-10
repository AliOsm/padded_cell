# frozen_string_literal: true

module PaddedCell
  # `bin/rails padded_cell` / `rake padded_cell`, with arguments in ARGS:
  #
  #   bin/rails padded_cell ARGS="-j 8 test/models"
  class Railtie < Rails::Railtie
    rake_tasks do
      desc 'Run the test suite with padded_cell (arguments in ARGS)'
      task :padded_cell do
        require 'padded_cell/cli'
        require 'shellwords'
        status = PaddedCell::CLI.start(Shellwords.split(ENV.fetch('ARGS', '')))
        exit status unless status.zero?
      end
    end
  end
end
