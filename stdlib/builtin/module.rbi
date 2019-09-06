# A `Module` is a collection of methods and constants. The methods in a
# module may be instance methods or module methods. Instance methods
# appear as methods in a class when the module is included, module methods
# do not. Conversely, module methods may be called without creating an
# encapsulating object, while instance methods may not. (See
# `Module#module_function` .)
# 
# In the descriptions that follow, the parameter *sym* refers to a symbol,
# which is either a quoted string or a `Symbol` (such as `:name` ).
# 
# ```ruby
# module Mod
#   include Math
#   CONST = 1
#   def meth
#     #  ...
#   end
# end
# Mod.class              #=> Module
# Mod.constants          #=> [:CONST, :PI, :E]
# Mod.instance_methods   #=> [:meth]
# ```
class Module < Object
  # In the first form, returns an array of the names of all constants
  # accessible from the point of call. This list includes the names of all
  # modules and classes defined in the global scope.
  # 
  # ```ruby
  # Module.constants.first(4)
  #    # => [:ARGF, :ARGV, :ArgumentError, :Array]
  # 
  # Module.constants.include?(:SEEK_SET)   # => false
  # 
  # class IO
  #   Module.constants.include?(:SEEK_SET) # => true
  # end
  # ```
  # 
  # The second form calls the instance method `constants` .
  def self.constants: () -> ::Array[Integer]

  # Returns the list of `Modules` nested at the point of call.
  # 
  # ```ruby
  # module M1
  #   module M2
  #     $a = Module.nesting
  #   end
  # end
  # $a           #=> [M1::M2, M1]
  # $a[0].name   #=> "M1::M2"
  # ```
  def self.nesting: () -> ::Array[Module]

  def <: (Module other) -> bool?

  def <=: (Module other) -> bool?

  def <=>: (Module other) -> Integer?

  def ==: (any other) -> bool

  def ===: (any other) -> bool

  def >: (Module other) -> bool?

  def >=: (Module other) -> bool?

  def alias_method: (Symbol new_name, Symbol old_name) -> self

  # Returns a list of modules included/prepended in *mod* (including *mod*
  # itself).
  # 
  # ```ruby
  # module Mod
  #   include Math
  #   include Comparable
  #   prepend Enumerable
  # end
  # 
  # Mod.ancestors        #=> [Enumerable, Mod, Comparable, Math]
  # Math.ancestors       #=> [Math]
  # Enumerable.ancestors #=> [Enumerable]
  # ```
  def ancestors: () -> ::Array[Module]

  def append_features: (Module arg0) -> self

  def `attr_accessor`: (*Symbol | String arg0) -> NilClass

  def `attr_reader`: (*Symbol | String arg0) -> NilClass

  def `attr_writer`: (*Symbol | String arg0) -> NilClass

  def autoload: (Symbol _module, String filename) -> NilClass

  def autoload?: (Symbol name) -> String?

  def class_eval: (String arg0, ?String filename, ?Integer lineno) -> any
                | [U] (any arg0) { (any m) -> U } -> U

  def class_exec: (*any args) { () -> any } -> any

  def class_variable_defined?: (Symbol | String arg0) -> bool

  def class_variable_get: (Symbol | String arg0) -> any

  def class_variable_set: (Symbol | String arg0, any arg1) -> any

  def class_variables: (?bool inherit) -> ::Array[Symbol]

  def const_defined?: (Symbol | String arg0, ?bool inherit) -> bool

  def const_get: (Symbol | String arg0, ?bool inherit) -> any

  def const_missing: (Symbol arg0) -> any

  def const_set: (Symbol | String arg0, any arg1) -> any

  def constants: (?bool inherit) -> ::Array[Symbol]

  def define_method: (Symbol | String arg0, ?Proc | Method | UnboundMethod arg1) -> Symbol
                   | (Symbol | String arg0) { () -> any } -> Symbol

  def eql?: (any other) -> bool

  def equal?: (any other) -> bool

  def extend_object: (any arg0) -> any

  def extended: (Module othermod) -> any

  # Prevents further modifications to *mod* .
  # 
  # This method returns self.
  def freeze: () -> self

  def `include`: (*Module arg0) -> self

  def `include?`: (Module arg0) -> bool

  def included: (Module othermod) -> any

  # Returns the list of modules included in *mod* .
  # 
  # ```ruby
  # module Mixin
  # end
  # 
  # module Outer
  #   include Mixin
  # end
  # 
  # Mixin.included_modules   #=> []
  # Outer.included_modules   #=> [Mixin]
  # ```
  def included_modules: () -> ::Array[Module]

  def initialize: () -> Object
                | () { (Module arg0) -> any } -> void

  def instance_method: (Symbol arg0) -> UnboundMethod

  def instance_methods: (?bool include_super) -> ::Array[Symbol]

  def method_added: (Symbol meth) -> any

  def method_defined?: (Symbol | String arg0) -> bool

  def method_removed: (Symbol method_name) -> any

  def module_eval: (String arg0, ?String filename, ?Integer lineno) -> any
                 | [U] (any arg0) { (any m) -> U } -> U

  def module_exec: (*any args) { () -> any } -> any

  def module_function: (*Symbol | String arg0) -> self

  # Returns the name of the module *mod* . Returns nil for anonymous
  # modules.
  def name: () -> String

  def `prepend`: (*Module arg0) -> self

  def prepend_features: (Module arg0) -> self

  def prepended: (Module othermod) -> any

  def `private`: (*Symbol | String arg0) -> self

  def private_class_method: (*Symbol | String arg0) -> self

  def private_constant: (*Symbol arg0) -> self

  def private_instance_methods: (?bool include_super) -> ::Array[Symbol]

  def private_method_defined?: (Symbol | String arg0) -> bool

  def protected: (*Symbol | String arg0) -> self

  def protected_instance_methods: (?bool include_super) -> ::Array[Symbol]

  def protected_method_defined?: (Symbol | String arg0) -> bool

  def `public`: (*Symbol | String arg0) -> self

  def public_class_method: (*Symbol | String arg0) -> self

  def public_constant: (*Symbol arg0) -> self

  def public_instance_method: (Symbol arg0) -> UnboundMethod

  def public_instance_methods: (?bool include_super) -> ::Array[Symbol]

  def public_method_defined?: (Symbol | String arg0) -> bool

  def refine: (Class arg0) { (any arg0) -> any } -> self

  def remove_class_variable: (Symbol arg0) -> any

  def remove_const: (Symbol arg0) -> any

  def remove_method: (Symbol | String arg0) -> self

  # Returns `true` if *mod* is a singleton class or `false` if it is an
  # ordinary class or module.
  # 
  # ```ruby
  # class C
  # end
  # C.singleton_class?                  #=> false
  # C.singleton_class.singleton_class?  #=> true
  # ```
  def `singleton_class?`: () -> bool

  def to_s: () -> String

  def undefMethod: (Symbol | String arg0) -> self

  def using: (Module arg0) -> self

  # Alias for: [to\_s](Module.downloaded.ruby_doc#method-i-to_s)
  def inspect: () -> String

  def attr: (*Symbol | String arg0) -> NilClass
end
