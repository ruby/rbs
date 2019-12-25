require_relative "test_helper"

class DirTest < StdlibTest
  target Dir
  using hook.refinement

  def test_children
    Dir.children('.')
    Dir.children('.', encoding: 'UTF-8')
    Dir.children('.', encoding: Encoding::UTF_8)
  end
end
