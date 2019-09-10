class Regexp < Object
  def self.escape: (String | Symbol arg0) -> String

  def self.last_match: () -> MatchData
                     | (?Integer arg0) -> String

  def self.try_convert: (any obj) -> Regexp?

  def ==: (any other) -> bool

  def ===: (any other) -> bool

  def =~: (String? str) -> Integer?

  # Returns the value of the case-insensitive flag.
  # 
  # ```ruby
  # /a/.casefold?           #=> false
  # /a/i.casefold?          #=> true
  # /(?i:a)/.casefold?      #=> false
  # ```
  def casefold?: () -> bool

  # Returns the [Encoding](https://ruby-doc.org/core-2.6.3/Encoding.html)
  # object that represents the encoding of obj.
  def encoding: () -> Encoding

  def fixed_encoding?: () -> bool

  # Produce a hash based on the text and options of this regular expression.
  # 
  # See also Object\#hash.
  def hash: () -> Integer

  def initialize: (String arg0, ?any options, ?String kcode) -> Object
                | (Regexp arg0) -> void

  # Produce a nicely formatted string-version of *rxp* . Perhaps
  # surprisingly, `#inspect` actually produces the more natural version of
  # the string than `#to_s` .
  # 
  # ```ruby
  # /ab+c/ix.inspect        #=> "/ab+c/ix"
  # ```
  def inspect: () -> String

  def match: (String? arg0, ?Integer arg1) -> MatchData?

  def named_captures: () -> ::Hash[String, ::Array[Integer]]

  def names: () -> ::Array[String]

  # Returns the set of bits corresponding to the options used when creating
  # this [Regexp](Regexp.downloaded.ruby_doc) (see `Regexp::new` for
  # details. Note that additional bits may be set in the returned options:
  # these are used internally by the regular expression code. These extra
  # bits are ignored if the options are passed to `Regexp::new` .
  # 
  # ```ruby
  # Regexp::IGNORECASE                  #=> 1
  # Regexp::EXTENDED                    #=> 2
  # Regexp::MULTILINE                   #=> 4
  # 
  # /cat/.options                       #=> 0
  # /cat/ix.options                     #=> 3
  # Regexp.new('cat', true).options     #=> 1
  # /\xa1\xa2/e.options                 #=> 16
  # 
  # r = /cat/ix
  # Regexp.new(r.source, r.options)     #=> /cat/ix
  # ```
  def options: () -> Integer

  # Returns the original string of the pattern.
  # 
  # ```ruby
  # /ab+c/ix.source #=> "ab+c"
  # ```
  # 
  # Note that escape sequences are retained as is.
  # 
  # ```ruby
  # /\x20\+/.source  #=> "\\x20\\+"
  # ```
  def source: () -> String

  # Returns a string containing the regular expression and its options
  # (using the `(?opts:source)` notation. This string can be fed back in to
  # `Regexp::new` to a regular expression with the same semantics as the
  # original. (However, `Regexp#==` may not return true when comparing the
  # two, as the source of the regular expression itself may differ, as the
  # example shows). `Regexp#inspect` produces a generally more readable
  # version of *rxp* .
  # 
  # ```ruby
  # r1 = /ab+c/ix           #=> /ab+c/ix
  # s1 = r1.to_s            #=> "(?ix-m:ab+c)"
  # r2 = Regexp.new(s1)     #=> /(?ix-m:ab+c)/
  # r1 == r2                #=> false
  # r1.source               #=> "ab+c"
  # r2.source               #=> "(?ix-m:ab+c)"
  # ```
  def to_s: () -> String

  def ~: () -> Integer?

  def self.compile: (String arg0, ?any options, ?String kcode) -> self
                  | (Regexp arg0) -> self

  def self.quote: (String | Symbol arg0) -> String

  def eql?: (any other) -> bool
end

Regexp::EXTENDED: Integer

Regexp::FIXEDENCODING: Integer

Regexp::IGNORECASE: Integer

Regexp::MULTILINE: Integer

Regexp::NOENCODING: Integer
