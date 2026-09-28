require_relative "test_helper"
require "find"

class FindSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "find"
  testing "singleton(::Find)"

  def test_version
    assert_const_type "String", "Find::VERSION"
  end
end

class FindTest < StdlibTest
  target Find
  library "find"

  def test_find
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      File.open("#{dir}/b", "w"){}

      Find.find(dir)
      Find.find("#{dir}/a", "#{dir}/b")
      Find.find(to_path_class.new(dir))
      Find.find(dir, ignore_error: true)
      Find.find(dir, ignore_error: :true)
      Find.find(dir){}
      Find.find("#{dir}/a", "#{dir}/b"){}
      Find.find(to_path_class.new(dir)){}
      Find.find(dir, ignore_error: true){}
      Find.find(dir, ignore_error: :true){}
    end
  end

  def test_prune
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}

      Find.find(dir) do
        Find.prune
      end
    end
  end

  private

  def to_path_class
    Class.new do
      def initialize(path)
        @path = path
      end

      def to_path
        @path
      end
    end
  end
end
