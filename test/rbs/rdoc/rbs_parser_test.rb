require "test_helper"

class RBSParserTest < Test::Unit::TestCase
  def parser(content)
    @tempfile = Tempfile.new self.class.name
    @filename = @tempfile.path

    RDoc::TopLevel.reset
    @top_level = RDoc::TopLevel.new @filename

    @options = RDoc::Options.new
    @options.quiet = true
    @stats = RDoc::Stats.new 0
    @parser = RDoc::Parser::RBS.new(@top_level, @filename, content, @options, @stats)
  end

  def teardown
    @tempfile.close
  end
end