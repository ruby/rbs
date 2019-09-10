# A rational number can be represented as a pair of integer numbers: a/b
# (b\>0), where a is the numerator and b is the denominator.
# [Integer](https://ruby-doc.org/core-2.6.3/Integer.html) a equals
# rational a/1 mathematically.
# 
# In Ruby, you can create rational objects with the Kernel\#Rational,
# [\#to\_r](Rational#method-i-to_r), or rationalize
# methods or by suffixing `r` to a literal. The return values will be
# irreducible fractions.
# 
#     Rational(1)      #=> (1/1)
#     Rational(2, 3)   #=> (2/3)
#     Rational(4, -6)  #=> (-2/3)
#     3.to_r           #=> (3/1)
#     2/3r             #=> (2/3)
# 
# You can also create rational objects from floating-point numbers or
# strings.
# 
# ```ruby
# Rational(0.3)    #=> (5404319552844595/18014398509481984)
# Rational('0.3')  #=> (3/10)
# Rational('2/3')  #=> (2/3)
# 
# 0.3.to_r         #=> (5404319552844595/18014398509481984)
# '0.3'.to_r       #=> (3/10)
# '2/3'.to_r       #=> (2/3)
# 0.3.rationalize  #=> (3/10)
# ```
# 
# A rational object is an exact number, which helps you to write programs
# without any rounding errors.
# 
# ```ruby
# 10.times.inject(0) {|t| t + 0.1 }              #=> 0.9999999999999999
# 10.times.inject(0) {|t| t + Rational('0.1') }  #=> (1/1)
# ```
# 
# However, when an expression includes an inexact component (numerical
# value or operation), it will produce an inexact result.
# 
# ```ruby
# Rational(10) / 3   #=> (10/3)
# Rational(10) / 3.0 #=> 3.3333333333333335
# 
# Rational(-8) ** Rational(1, 3)
#                    #=> (1.0000000000000002+1.7320508075688772i)
# ```
class Rational < Numeric
  def %: (Integer arg0) -> Rational
       | (Float arg0) -> Float
       | (Rational arg0) -> Rational
       | (BigDecimal arg0) -> BigDecimal

  def *: (Integer arg0) -> Rational
       | (Float arg0) -> Float
       | (Rational arg0) -> Rational
       | (BigDecimal arg0) -> BigDecimal
       | (Complex arg0) -> Complex

  def **: (Integer arg0) -> Numeric
        | (Float arg0) -> Numeric
        | (Rational arg0) -> Numeric
        | (BigDecimal arg0) -> BigDecimal
        | (Complex arg0) -> Complex

  def +: (Integer arg0) -> Rational
       | (Float arg0) -> Float
       | (Rational arg0) -> Rational
       | (BigDecimal arg0) -> BigDecimal
       | (Complex arg0) -> Complex

  def +@: () -> Rational

  def -: (Integer arg0) -> Rational
       | (Float arg0) -> Float
       | (Rational arg0) -> Rational
       | (BigDecimal arg0) -> BigDecimal
       | (Complex arg0) -> Complex

  def -@: () -> Rational

  def /: (Integer arg0) -> Rational
       | (Float arg0) -> Float
       | (Rational arg0) -> Rational
       | (BigDecimal arg0) -> BigDecimal
       | (Complex arg0) -> Complex

  def <: (Integer arg0) -> bool
       | (Float arg0) -> bool
       | (Rational arg0) -> bool
       | (BigDecimal arg0) -> bool

  def <=: (Integer arg0) -> bool
        | (Float arg0) -> bool
        | (Rational arg0) -> bool
        | (BigDecimal arg0) -> bool

  def <=>: (Integer arg0) -> Integer
         | (Float arg0) -> Integer
         | (Rational arg0) -> Integer
         | (BigDecimal arg0) -> Integer

  def ==: (Object arg0) -> bool

  def >: (Integer arg0) -> bool
       | (Float arg0) -> bool
       | (Rational arg0) -> bool
       | (BigDecimal arg0) -> bool

  def >=: (Integer arg0) -> bool
        | (Float arg0) -> bool
        | (Rational arg0) -> bool
        | (BigDecimal arg0) -> bool

  # Returns the absolute value of `rat` .
  # 
  #     (1/2r).abs    #=> (1/2)
  #     (-1/2r).abs   #=> (1/2)
  # 
  # [\#magnitude](Rational.downloaded.ruby_doc#method-i-magnitude) is an
  # alias for [\#abs](Rational.downloaded.ruby_doc#method-i-abs).
  def abs: () -> Rational

  def abs2: () -> Rational

  def angle: () -> Numeric

  def arg: () -> Numeric

  # Returns the smallest number greater than or equal to `rat` with a
  # precision of `ndigits` decimal digits (default: 0).
  # 
  # When the precision is negative, the returned value is an integer with at
  # least `ndigits.abs` trailing zeros.
  # 
  # Returns a rational when `ndigits` is positive, otherwise returns an
  # integer.
  # 
  # ```ruby
  # Rational(3).ceil      #=> 3
  # Rational(2, 3).ceil   #=> 1
  # Rational(-3, 2).ceil  #=> -1
  # 
  #   #    decimal      -  1  2  3 . 4  5  6
  #   #                   ^  ^  ^  ^   ^  ^
  #   #   precision      -3 -2 -1  0  +1 +2
  # 
  # Rational('-123.456').ceil(+1).to_f  #=> -123.4
  # Rational('-123.456').ceil(-1)       #=> -120
  # ```
  def ceil: () -> Integer
          | (?Integer digits) -> Numeric

  def coerce: (Integer arg0) -> [ Rational, Rational ]
            | (Float arg0) -> [ Float, Float ]
            | (Rational arg0) -> [ Rational, Rational ]
            | (Complex arg0) -> [ Numeric, Numeric ]

  def conj: () -> Rational

  def conjugate: () -> Rational

  # Returns the denominator (always positive).
  # 
  # ```ruby
  # Rational(7).denominator             #=> 1
  # Rational(7, 1).denominator          #=> 1
  # Rational(9, -4).denominator         #=> 4
  # Rational(-2, -10).denominator       #=> 5
  # ```
  def denominator: () -> Integer

  def div: (Integer arg0) -> Integer
         | (Float arg0) -> Integer
         | (Rational arg0) -> Integer
         | (BigDecimal arg0) -> Integer

  def divmod: (Integer | Float | Rational | BigDecimal arg0) -> [ Integer | Float | Rational | BigDecimal, Integer | Float | Rational | BigDecimal ]

  def equal?: (Object arg0) -> bool

  def fdiv: (Integer arg0) -> Float
          | (Float arg0) -> Float
          | (Rational arg0) -> Float
          | (BigDecimal arg0) -> Float
          | (Complex arg0) -> Float

  # Returns the largest number less than or equal to `rat` with a precision
  # of `ndigits` decimal digits (default: 0).
  # 
  # When the precision is negative, the returned value is an integer with at
  # least `ndigits.abs` trailing zeros.
  # 
  # Returns a rational when `ndigits` is positive, otherwise returns an
  # integer.
  # 
  # ```ruby
  # Rational(3).floor      #=> 3
  # Rational(2, 3).floor   #=> 0
  # Rational(-3, 2).floor  #=> -2
  # 
  #   #    decimal      -  1  2  3 . 4  5  6
  #   #                   ^  ^  ^  ^   ^  ^
  #   #   precision      -3 -2 -1  0  +1 +2
  # 
  # Rational('-123.456').floor(+1).to_f  #=> -123.5
  # Rational('-123.456').floor(-1)       #=> -130
  # ```
  def floor: () -> Integer
           | (?Integer digits) -> Numeric

  def hash: () -> Integer

  def imag: () -> Integer

  def imaginary: () -> Integer

  # Returns the value as a string for inspection.
  # 
  # ```ruby
  # Rational(2).inspect      #=> "(2/1)"
  # Rational(-8, 6).inspect  #=> "(-4/3)"
  # Rational('1/2').inspect  #=> "(1/2)"
  # ```
  def inspect: () -> String

  def modulo: (Integer arg0) -> Rational
            | (Float arg0) -> Float
            | (Rational arg0) -> Rational
            | (BigDecimal arg0) -> BigDecimal

  # Returns the numerator.
  # 
  # ```ruby
  # Rational(7).numerator        #=> 7
  # Rational(7, 1).numerator     #=> 7
  # Rational(9, -4).numerator    #=> -9
  # Rational(-2, -10).numerator  #=> 1
  # ```
  def numerator: () -> Integer

  def phase: () -> Numeric

  def quo: (Integer arg0) -> Rational
         | (Float arg0) -> Float
         | (Rational arg0) -> Rational
         | (BigDecimal arg0) -> BigDecimal
         | (Complex arg0) -> Complex

  # Returns a simpler approximation of the value if the optional argument
  # `eps` is given (rat-|eps| \<= result \<= rat+|eps|), self otherwise.
  # 
  # ```ruby
  # r = Rational(5033165, 16777216)
  # r.rationalize                    #=> (5033165/16777216)
  # r.rationalize(Rational('0.01'))  #=> (3/10)
  # r.rationalize(Rational('0.1'))   #=> (1/3)
  # ```
  def rationalize: () -> Rational
                 | (?Numeric arg0) -> Rational

  def real: () -> Rational

  def real?: () -> TrueClass

  # Returns `rat` rounded to the nearest value with a precision of `ndigits`
  # decimal digits (default: 0).
  # 
  # When the precision is negative, the returned value is an integer with at
  # least `ndigits.abs` trailing zeros.
  # 
  # Returns a rational when `ndigits` is positive, otherwise returns an
  # integer.
  # 
  # ```ruby
  # Rational(3).round      #=> 3
  # Rational(2, 3).round   #=> 1
  # Rational(-3, 2).round  #=> -2
  # 
  #   #    decimal      -  1  2  3 . 4  5  6
  #   #                   ^  ^  ^  ^   ^  ^
  #   #   precision      -3 -2 -1  0  +1 +2
  # 
  # Rational('-123.456').round(+1).to_f  #=> -123.5
  # Rational('-123.456').round(-1)       #=> -120
  # ```
  # 
  # The optional `half` keyword argument is available similar to
  # [Float\#round](https://ruby-doc.org/core-2.6.3/Float.html#method-i-round)
  # .
  # 
  # ```ruby
  # Rational(25, 100).round(1, half: :up)    #=> (3/10)
  # Rational(25, 100).round(1, half: :down)  #=> (1/5)
  # Rational(25, 100).round(1, half: :even)  #=> (1/5)
  # Rational(35, 100).round(1, half: :up)    #=> (2/5)
  # Rational(35, 100).round(1, half: :down)  #=> (3/10)
  # Rational(35, 100).round(1, half: :even)  #=> (2/5)
  # Rational(-25, 100).round(1, half: :up)   #=> (-3/10)
  # Rational(-25, 100).round(1, half: :down) #=> (-1/5)
  # Rational(-25, 100).round(1, half: :even) #=> (-1/5)
  # ```
  def round: () -> Integer
           | (?Integer arg0) -> Numeric

  def to_c: () -> Complex

  # Returns the value as a
  # [Float](https://ruby-doc.org/core-2.6.3/Float.html).
  # 
  # ```ruby
  # Rational(2).to_f      #=> 2.0
  # Rational(9, 4).to_f   #=> 2.25
  # Rational(-3, 4).to_f  #=> -0.75
  # Rational(20, 3).to_f  #=> 6.666666666666667
  # ```
  def to_f: () -> Float

  # Returns the truncated value as an integer.
  # 
  # Equivalent to
  # [\#truncate](Rational.downloaded.ruby_doc#method-i-truncate).
  # 
  # ```ruby
  # Rational(2, 3).to_i    #=> 0
  # Rational(3).to_i       #=> 3
  # Rational(300.6).to_i   #=> 300
  # Rational(98, 71).to_i  #=> 1
  # Rational(-31, 2).to_i  #=> -15
  # ```
  def to_i: () -> Integer

  # Returns self.
  # 
  # ```ruby
  # Rational(2).to_r      #=> (2/1)
  # Rational(-8, 6).to_r  #=> (-4/3)
  # ```
  def to_r: () -> Rational

  # Returns the value as a string.
  # 
  # ```ruby
  # Rational(2).to_s      #=> "2/1"
  # Rational(-8, 6).to_s  #=> "-4/3"
  # Rational('1/2').to_s  #=> "1/2"
  # ```
  def to_s: () -> String

  # Returns `rat` truncated (toward zero) to a precision of `ndigits`
  # decimal digits (default: 0).
  # 
  # When the precision is negative, the returned value is an integer with at
  # least `ndigits.abs` trailing zeros.
  # 
  # Returns a rational when `ndigits` is positive, otherwise returns an
  # integer.
  # 
  # ```ruby
  # Rational(3).truncate      #=> 3
  # Rational(2, 3).truncate   #=> 0
  # Rational(-3, 2).truncate  #=> -1
  # 
  #   #    decimal      -  1  2  3 . 4  5  6
  #   #                   ^  ^  ^  ^   ^  ^
  #   #   precision      -3 -2 -1  0  +1 +2
  # 
  # Rational('-123.456').truncate(+1).to_f  #=> -123.4
  # Rational('-123.456').truncate(-1)       #=> -120
  # ```
  def truncate: () -> Integer
              | (?Integer arg0) -> Rational

  def zero?: () -> bool
end
