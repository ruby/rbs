require_relative "test_helper"
require 'tempfile'

class IOTest < StdlibTest
  target IO
  using hook.refinement

  def test_set_encoding_by_bom
    open(IO::NULL, 'rb') do |f|
      f.set_encoding_by_bom
    end

    file = Tempfile.new('test_set_encoding_by_bom')
    file.write("\u{FEFF}abc")
    file.close
    open(file.path, 'rb') do |f|
      f.set_encoding_by_bom
    end
  end
end
