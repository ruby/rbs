# Objects of class `Dir` are directory streams representing directories in
# the underlying file system. They provide a variety of ways to list
# directories and their contents. See also `File` .
# 
# The directory used in these examples contains the two regular files (
# `config.h` and `main.rb` ), the parent directory ( `..` ), and the
# directory itself ( `.` ).
class Dir < Object
  include Enumerable[String]

  def self.chdir: (?String | Pathname arg0) -> Integer
                | [U] (?String | Pathname arg0) { (String arg0) -> U } -> U

  def self.chroot: (String arg0) -> Integer

  def self.delete: (String arg0) -> Integer

  def self.entries: (String arg0, ?Encoding arg1) -> ::Array[String]

  def self.exist?: (String file) -> bool

  def self.foreach: (String dir, ?Encoding arg0) { (String arg0) -> any } -> NilClass
                  | (String dir, ?Encoding arg0) -> ::Enumerator[String]

  # Returns the path to the current working directory of this process as a
  # string.
  # 
  # ```ruby
  # Dir.chdir("/tmp")   #=> 0
  # Dir.getwd           #=> "/tmp"
  # Dir.pwd             #=> "/tmp"
  # ```
  def self.getwd: () -> String

  def self.glob: (String | ::Array[String] pattern, ?Integer flags) -> ::Array[String]
               | (String | ::Array[String] pattern, ?Integer flags) { (String arg0) -> any } -> NilClass

  def self.home: (?String arg0) -> String

  def self.mkdir: (String arg0, ?Integer arg1) -> Integer

  def self.open: (String arg0, ?Encoding arg1) -> Dir
               | [U] (String arg0, ?Encoding arg1) { (Dir arg0) -> U } -> U

  # Returns the path to the current working directory of this process as a
  # string.
  # 
  # ```ruby
  # Dir.chdir("/tmp")   #=> 0
  # Dir.getwd           #=> "/tmp"
  # Dir.pwd             #=> "/tmp"
  # ```
  def self.pwd: () -> String

  def self.rmdir: (String arg0) -> Integer

  def self.unlink: (String arg0) -> Integer

  # Closes the directory stream. Calling this method on closed
  # [Dir](Dir.downloaded.ruby_doc) object is ignored since Ruby 2.3.
  # 
  # ```ruby
  # d = Dir.new("testdir")
  # d.close   #=> nil
  # ```
  def close: () -> NilClass

  def each: () { (String arg0) -> any } -> self
          | () -> ::Enumerator[String]

  # Returns the file descriptor used in *dir* .
  # 
  # ```ruby
  # d = Dir.new("..")
  # d.fileno   #=> 8
  # ```
  # 
  # This method uses dirfd() function defined by POSIX 2008.
  # [NotImplementedError](https://ruby-doc.org/core-2.6.3/NotImplementedError.html)
  # is raised on other platforms, such as Windows, which doesn’t provide the
  # function.
  def fileno: () -> Integer

  def initialize: (String arg0, ?Encoding arg1) -> void

  # Return a string describing this [Dir](Dir.downloaded.ruby_doc) object.
  def inspect: () -> String

  # Returns the path parameter passed to *dir* ’s constructor.
  # 
  # ```ruby
  # d = Dir.new("..")
  # d.path   #=> ".."
  # ```
  def path: () -> String?

  # Returns the current position in *dir* . See also `Dir#seek` .
  # 
  # ```ruby
  # d = Dir.new("testdir")
  # d.tell   #=> 0
  # d.read   #=> "."
  # d.tell   #=> 12
  # ```
  def pos: () -> Integer

  def pos=: (Integer arg0) -> Integer

  # Reads the next entry from *dir* and returns it as a string. Returns
  # `nil` at the end of the stream.
  # 
  # ```ruby
  # d = Dir.new("testdir")
  # d.read   #=> "."
  # d.read   #=> ".."
  # d.read   #=> "config.h"
  # ```
  def read: () -> String?

  def rewind: () -> self

  def seek: (Integer arg0) -> self

  # Returns the current position in *dir* . See also `Dir#seek` .
  # 
  # ```ruby
  # d = Dir.new("testdir")
  # d.tell   #=> 0
  # d.read   #=> "."
  # d.tell   #=> 12
  # ```
  def tell: () -> Integer

  # Returns the path parameter passed to *dir* ’s constructor.
  # 
  # ```ruby
  # d = Dir.new("..")
  # d.path   #=> ".."
  # ```
  def to_path: () -> String?

  def self.[]: (String | ::Array[String] pattern, ?Integer flags) -> ::Array[String]
             | (String | ::Array[String] pattern, ?Integer flags) { (String arg0) -> any } -> NilClass
end
