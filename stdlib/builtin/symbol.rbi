# `Symbol` objects represent names and some strings inside the Ruby
# interpreter. They are generated using the `:name` and `:"string"`
# literals syntax, and by the various `to_sym` methods. The same `Symbol`
# object will be created for a given name or string for the duration of a
# program's execution, regardless of the context or meaning of that name.
# Thus if `Fred` is a constant in one context, a method in another, and a
# class in a third, the `Symbol` `:Fred` will be the same object in all
# three contexts.
# 
# ```ruby
# module One
#   class Fred
#   end
#   $f1 = :Fred
# end
# module Two
#   Fred = 1
#   $f2 = :Fred
# end
# def Fred()
# end
# $f3 = :Fred
# $f1.object_id   #=> 2514190
# $f2.object_id   #=> 2514190
# $f3.object_id   #=> 2514190
# ```
class Symbol < Object
  include Comparable

  # Returns an array of all the symbols currently in Ruby's symbol table.
  # 
  #     Symbol.all_symbols.size    #=> 903
  #     Symbol.all_symbols[1,20]   #=> [:floor, :ARGV, :Binding, :symlink,
  #                                     :chown, :EOFError, :$;, :String,
  #                                     :LOCK_SH, :"setuid?", :$<,
  #                                     :default_proc, :compact, :extend,
  #                                     :Tms, :getwd, :$=, :ThreadGroup,
  #                                     :wait2, :$>]
  def self.all_symbols: () -> ::Array[Symbol]

  def <=>: (Symbol other) -> Integer?

  def ==: (any obj) -> bool

  def =~: (any obj) -> Integer?

  def []: (Integer idx_or_range) -> String
        | (Integer idx_or_range, ?Integer n) -> String
        | (::Range[Integer] idx_or_range) -> String

  # Same as `sym.to_s.capitalize.intern` .
  def capitalize: () -> Symbol

  def casecmp: (Symbol other) -> Integer?

  def casecmp?: (Symbol other) -> bool?

  # Same as `sym.to_s.downcase.intern` .
  def downcase: () -> Symbol

  # Returns whether *sym* is :“” or not.
  def empty?: () -> bool

  # Returns the [Encoding](https://ruby-doc.org/core-2.6.3/Encoding.html)
  # object that represents the encoding of *sym* .
  def encoding: () -> Encoding

  # Returns the name or string corresponding to *sym* .
  # 
  # ```ruby
  # :fred.id2name   #=> "fred"
  # :ginger.to_s    #=> "ginger"
  # ```
  def id2name: () -> String

  # Returns the representation of *sym* as a symbol literal.
  # 
  # ```ruby
  # :fred.inspect   #=> ":fred"
  # ```
  def inspect: () -> String

  # In general, `to_sym` returns the `Symbol` corresponding to an object. As
  # *sym* is already a symbol, `self` is returned in this case.
  def intern: () -> self

  # Same as `sym.to_s.length` .
  def length: () -> Integer

  def match: (any obj) -> Integer?

  def match?: (*any args) -> any

  # Same as `sym.to_s.succ.intern` .
  def next: () -> Symbol

  # Same as `sym.to_s.succ.intern` .
  def succ: () -> Symbol

  # Same as `sym.to_s.swapcase.intern` .
  def swapcase: () -> Symbol

  # Returns a *Proc* object which responds to the given method by *sym* .
  # 
  # ```ruby
  # (1..3).collect(&:to_s)  #=> ["1", "2", "3"]
  # ```
  def to_proc: () -> Proc

  # Same as `sym.to_s.upcase.intern` .
  def upcase: () -> Symbol

  # Same as `sym.to_s.length` .
  def size: () -> Integer

  def slice: (Integer idx_or_range) -> String
           | (Integer idx_or_range, ?Integer n) -> String
           | (::Range[Integer] idx_or_range) -> String

  # Returns the name or string corresponding to *sym* .
  # 
  # ```ruby
  # :fred.id2name   #=> "fred"
  # :ginger.to_s    #=> "ginger"
  # ```
  def to_s: () -> String

  # In general, `to_sym` returns the `Symbol` corresponding to an object. As
  # *sym* is already a symbol, `self` is returned in this case.
  def to_sym: () -> self
end
