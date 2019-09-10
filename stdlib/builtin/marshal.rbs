# The marshaling library converts collections of Ruby objects into a byte
# stream, allowing them to be stored outside the currently active script.
# This data may subsequently be read and the original objects
# reconstituted.
# 
# Marshaled data has major and minor version numbers stored along with the
# object information. In normal use, marshaling can only load data written
# with the same major version number and an equal or lower minor version
# number. If Ruby’s “verbose” flag is set (normally using -d, -v, -w, or
# –verbose) the major and minor numbers must match exactly.
# [Marshal](Marshal) versioning is independent of
# Ruby’s version numbers. You can extract the version by reading the
# first two bytes of marshaled data.
# 
# ```ruby
# str = Marshal.dump("thing")
# RUBY_VERSION   #=> "1.9.0"
# str[0].ord     #=> 4
# str[1].ord     #=> 8
# ```
# 
# Some objects cannot be dumped: if the objects to be dumped include
# bindings, procedure or method objects, instances of class
# [IO](https://ruby-doc.org/core-2.6.3/IO.html), or singleton objects, a
# [TypeError](https://ruby-doc.org/core-2.6.3/TypeError.html) will be
# raised.
# 
# If your class has special serialization needs (for example, if you want
# to serialize in some specific format), or if it contains objects that
# would otherwise not be serializable, you can implement your own
# serialization strategy.
# 
# There are two methods of doing this, your object can define either
# marshal\_dump and marshal\_load or \_dump and \_load. marshal\_dump will
# take precedence over \_dump if both are defined. marshal\_dump may
# result in smaller [Marshal](Marshal) strings.
# 
# 
# By design, [::load](Marshal#method-c-load) can
# deserialize almost any class loaded into the Ruby process. In many cases
# this can lead to remote code execution if the
# [Marshal](Marshal) data is loaded from an untrusted
# source.
# 
# As a result, [::load](Marshal#method-c-load) is not
# suitable as a general purpose serialization format and you should never
# unmarshal user supplied input or other untrusted data.
# 
# If you need to deserialize untrusted data, use JSON or another
# serialization format that is only able to load simple, ‘primitive’ types
# such as [String](https://ruby-doc.org/core-2.6.3/String.html),
# [Array](https://ruby-doc.org/core-2.6.3/Array.html),
# [Hash](https://ruby-doc.org/core-2.6.3/Hash.html), etc. Never allow
# user input to specify arbitrary types to deserialize into.
# 
# 
# When dumping an object the method marshal\_dump will be called.
# marshal\_dump must return a result containing the information necessary
# for marshal\_load to reconstitute the object. The result can be any
# object.
# 
# When loading an object dumped using marshal\_dump the object is first
# allocated then marshal\_load is called with the result from
# marshal\_dump. marshal\_load must recreate the object from the
# information in the result.
# 
# Example:
# 
# ```ruby
# class MyObj
#   def initialize name, version, data
#     @name    = name
#     @version = version
#     @data    = data
#   end
# 
#   def marshal_dump
#     [@name, @version]
#   end
# 
#   def marshal_load array
#     @name, @version = array
#   end
# end
# ```
# 
# 
# Use \_dump and \_load when you need to allocate the object you’re
# restoring yourself.
# 
# When dumping an object the instance method \_dump is called with an
# [Integer](https://ruby-doc.org/core-2.6.3/Integer.html) which indicates
# the maximum depth of objects to dump (a value of -1 implies that you
# should disable depth checking). \_dump must return a
# [String](https://ruby-doc.org/core-2.6.3/String.html) containing the
# information necessary to reconstitute the object.
# 
# The class method \_load should take a
# [String](https://ruby-doc.org/core-2.6.3/String.html) and use it to
# return an object of the same class.
# 
# Example:
# 
# ```ruby
# class MyObj
#   def initialize name, version, data
#     @name    = name
#     @version = version
#     @data    = data
#   end
# 
#   def _dump level
#     [@name, @version].join ':'
#   end
# 
#   def self._load args
#     new(*args.split(':'))
#   end
# end
# ```
# 
# Since [::dump](Marshal#method-c-dump) outputs a
# string you can have \_dump return a
# [Marshal](Marshal) string which is Marshal.loaded in
# \_load for complex objects.
module Marshal
  def self.dump: (Object arg0, ?IO arg1, ?Integer arg2) -> Object
               | (Object arg0, ?Integer arg1) -> Object

  def self.load: (String arg0, ?Proc arg1) -> Object
end

Marshal::MAJOR_VERSION: Integer

Marshal::MINOR_VERSION: Integer
