require_relative "test_helper"

require "tsort"

class TSortSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library 'tsort'
  testing "singleton(::TSort)"

  class EachNode
    def initialize(*nodes)
      @nodes = nodes
    end

    def call(&block)
      @nodes.each(&block)
    end
  end

  class EachChild
    def initialize(hash)
      @hash = hash
    end

    def call(node, &block)
      @hash[node].each(&block)
    end
  end

  def test_each_strongly_connected_component
    assert_send_type "(::TSortSingletonTest::EachNode, ::TSortSingletonTest::EachChild) { (Array[Integer]) -> void } -> void",
                     TSort, :each_strongly_connected_component,
                     EachNode.new(1, 2, 3, 4),
                     EachChild.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] }) do end

    assert_send_type "(::TSortSingletonTest::EachNode, ::TSortSingletonTest::EachChild) -> Enumerator[Array[Integer], void]",
                     TSort, :each_strongly_connected_component,
                     EachNode.new(1, 2, 3, 4),
                     EachChild.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] })
  end

  def test_each_strongly_connected_component_from
    assert_send_type "(Integer, ::TSortSingletonTest::EachChild) { (Array[Integer]) -> void } -> void",
                     TSort, :each_strongly_connected_component_from,
                     1,
                     EachChild.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] }) do end

    assert_send_type "(Integer, ::TSortSingletonTest::EachChild) -> Enumerator[Array[Integer], void]",
                     TSort, :each_strongly_connected_component_from,
                     1,
                     EachChild.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] })
  end

  def test_strongly_connected_components
    assert_send_type "(::TSortSingletonTest::EachNode, ::TSortSingletonTest::EachChild) -> Array[Array[Integer]]",
                     TSort, :strongly_connected_components,
                     EachNode.new(1, 2, 3, 4),
                     EachChild.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] })
  end

  def test_tsort
    assert_send_type "(::TSortSingletonTest::EachNode, ::TSortSingletonTest::EachChild) -> Array[Integer]",
                     TSort, :tsort,
                     EachNode.new(1, 2, 3, 4),
                     EachChild.new({ 1 => [2], 2 => [4], 3 => [2, 4], 4 => [] })
  end

  def test_tsort_each
    assert_send_type "(::TSortSingletonTest::EachNode, ::TSortSingletonTest::EachChild) { (Integer) -> void } -> void",
                     TSort, :tsort_each,
                     EachNode.new(1, 2, 3, 4),
                     EachChild.new({ 1 => [2], 2 => [4], 3 => [2, 4], 4 => [] }) do end

    assert_send_type "(::TSortSingletonTest::EachNode, ::TSortSingletonTest::EachChild) -> Enumerator[Integer, void]",
                     TSort, :tsort_each,
                     EachNode.new(1, 2, 3, 4),
                     EachChild.new({ 1 => [2], 2 => [4], 3 => [2, 4], 4 => [] })
  end
end

class TSortInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library 'tsort'
  testing "::TSort[::Integer]"

  class Sort
    def initialize(hash)
      @hash = hash
    end

    include TSort

    def tsort_each_node(&block)
      @hash.each_key(&block)
    end

    def tsort_each_child(node, &block)
      (@hash[node] || []).each(&block)
    end
  end

  def test_each_strongly_connected_component
    assert_send_type "() { (Array[Integer]) -> void } -> void",
                     Sort.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] }),
                     :each_strongly_connected_component do end

    assert_send_type "() -> Enumerator[Array[Integer], void]",
                     Sort.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] }),
                     :each_strongly_connected_component
  end

  def test_each_strongly_connected_component_from
    assert_send_type "(Integer) { (Array[Integer]) -> void } -> void",
                     Sort.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] }),
                     :each_strongly_connected_component_from,
                     1 do end

    assert_send_type "(Integer) -> Enumerator[Array[Integer], void]",
                     Sort.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] }),
                     :each_strongly_connected_component_from,
                     1
  end

  def test_strongly_connected_components
    assert_send_type "() -> Array[Array[Integer]]",
                     Sort.new({ 1 => [2], 2 => [3, 4], 3 => [2], 4 => [] }),
                     :strongly_connected_components
  end

  def test_tsort
    assert_send_type "() -> Array[Integer]",
                     Sort.new({ 1 => [2, 3], 2 => [4], 3 => [2, 4], 4 => [] }),
                     :tsort
  end

  def test_tsort_each
    assert_send_type "() { (Integer) -> void } -> void",
                     Sort.new({ 1 => [2, 3], 2 => [4], 3 => [2, 4], 4 => [] }),
                     :tsort_each do end

    assert_send_type "() -> Enumerator[Integer, void]",
                     Sort.new({ 1 => [2, 3], 2 => [4], 3 => [2, 4], 4 => [] }),
                     :tsort_each
  end
end
