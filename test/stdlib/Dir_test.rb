require_relative "test_helper"

class DirTest < StdlibTest
  target Dir
  using hook.refinement

  def test_children
    Dir.children('.')
    Dir.children('.', encoding: 'UTF-8')
    Dir.children('.', encoding: Encoding::UTF_8)
    Dir.new('.').children
  end

  def test_each_child
    Dir.each_child('.')
    Dir.each_child('.') { }
    Dir.each_child('.', encoding: 'UTF-8')
    Dir.each_child('.', encoding: Encoding::UTF_8)
    Dir.new('.').each_child
    # Dir.new('.').each_child { |filename| }
  end
end
