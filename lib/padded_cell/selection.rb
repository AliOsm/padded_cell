# frozen_string_literal: true

module PaddedCell
  # What to run, from command line arguments, the way `rails test` reads them:
  #
  #   (none)                  test/**/*_test.rb, minus test/{system,dummy,fixtures}
  #   test/models             every *_test.rb below it
  #   test/models/a_test.rb   that file
  #   a_test.rb:12            the test whose definition spans line 12
  #   a_test.rb:12-20:31      tests overlapping 12..20, or spanning 31
  #   'test/**/*_x_test.rb'   a glob
  class Selection
    DEFAULT_GLOB = 'test/**/*_test.rb'
    DEFAULT_EXCLUDE = 'test/{system,dummy,fixtures}/**/*_test.rb'
    LINES = /(?::\d+(?:-\d+)?)+\z/

    # Absolute paths, sorted.
    attr_reader :files

    def self.parse(args, root: Dir.pwd) = new(args, root)

    def initialize(args, root)
      @root = root
      @lines = Hash.new { |hash, file| hash[file] = [] }
      @files = (args.empty? ? defaults : args.flat_map { expand(it) }).uniq.sort
    end

    # Line ranges asked for each file; empty when the whole file runs.
    def lines_for(file) = @lines.fetch(file, [])

    def line_filtered? = @lines.any?

    # Whether a test defined in file over lines is selected by line.
    def covers?(file, lines)
      ranges = lines_for(file)
      ranges.empty? || ranges.any? { it.begin <= lines.end && lines.begin <= it.end }
    end

    private

    def defaults
      Dir.glob(DEFAULT_GLOB, base: @root).map { absolute(it) } -
        Dir.glob(DEFAULT_EXCLUDE, base: @root).map { absolute(it) }
    end

    def expand(arg)
      if (match = LINES.match(arg))
        file = existing_file(match.pre_match, arg)
        @lines[file].concat(ranges(match[0]))
        [file]
      elsif glob?(arg)
        Dir.glob(arg, base: @root).map { absolute(it) }
      elsif File.directory?(absolute(arg))
        Dir.glob('**/*_test.rb', base: absolute(arg)).map { File.join(absolute(arg), it) }
      else
        [existing_file(arg, arg)]
      end
    end

    def ranges(spec)
      spec.delete_prefix(':').split(':').map do |part|
        first, last = part.split('-').map { Integer(it, 10) }
        first..(last || first)
      end
    end

    def existing_file(path, arg)
      file = absolute(path)
      raise ArgumentError, "no such test file: #{arg}" unless File.file?(file)

      file
    end

    def glob?(arg) = arg.match?(/[*?\[{]/)

    def absolute(path) = File.expand_path(path, @root)
  end
end
