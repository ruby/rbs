require_relative "../test_helper"
require "rubygems/package"
require "stringio"

class GemPackageTarHeaderSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Gem::Package::TarHeader)"

  def test_new
    assert_send_type "(Hash[Symbol, untyped]) -> Gem::Package::TarHeader",
                     Gem::Package::TarHeader, :new, { name: "foo.txt", size: 11, prefix: "", mode: 0644 }
  end
end

class GemPackageTarReaderSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Gem::Package::TarReader)"

  def test_new
    assert_send_type "(untyped) -> Gem::Package::TarReader",
                     Gem::Package::TarReader, :new, StringIO.new("".b)
    assert_send_type "(untyped) { (Gem::Package::TarReader) -> void } -> nil",
                     Gem::Package::TarReader, :new, StringIO.new("".b) do end
  end
end

class GemPackageTarReaderEntrySingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Gem::Package::TarReader::Entry)"

  def test_new
    header = Gem::Package::TarHeader.new(name: "foo.txt", size: 11, prefix: "", mode: 0644)
    assert_send_type "(Gem::Package::TarHeader, untyped) -> Gem::Package::TarReader::Entry",
                     Gem::Package::TarReader::Entry, :new, header, StringIO.new("".b)
  end
end
