# A complex number can be represented as a paired real number with
# imaginary unit; a+bi. Where a is real part, b is imaginary part and i is
# imaginary unit. Real a equals complex a+0i mathematically.
# 
# [Complex](Complex) object can be created as literal,
# and also by using Kernel\#Complex,
# [::rect](Complex#method-c-rect),
# [::polar](Complex#method-c-polar) or
# [\#to\_c](Complex#method-i-to_c) method.
# 
#     2+1i                 #=> (2+1i)
#     Complex(1)           #=> (1+0i)
#     Complex(2, 3)        #=> (2+3i)
#     Complex.polar(2, 3)  #=> (-1.9799849932008908+0.2822400161197344i)
#     3.to_c               #=> (3+0i)
# 
# You can also create complex object from floating-point numbers or
# strings.
# 
# ```ruby
# Complex(0.3)         #=> (0.3+0i)
# Complex('0.3-0.5i')  #=> (0.3-0.5i)
# Complex('2/3+3/4i')  #=> ((2/3)+(3/4)*i)
# Complex('1@2')       #=> (-0.4161468365471424+0.9092974268256817i)
# 
# 0.3.to_c             #=> (0.3+0i)
# '0.3-0.5i'.to_c      #=> (0.3-0.5i)
# '2/3+3/4i'.to_c      #=> ((2/3)+(3/4)*i)
# '1@2'.to_c           #=> (-0.4161468365471424+0.9092974268256817i)
# ```
# 
# A complex object is either an exact or an inexact number.
# 
# ```ruby
# Complex(1, 1) / 2    #=> ((1/2)+(1/2)*i)
# Complex(1, 1) / 2.0  #=> (0.5+0.5i)
# ```
class Complex < Numeric
  def *: (Integer arg0) -> Complex
       | (Float arg0) -> Complex
       | (Rational arg0) -> Complex
       | (BigDecimal arg0) -> Complex
       | (Complex arg0) -> Complex

  def **: (Integer arg0) -> Complex
        | (Float arg0) -> Complex
        | (Rational arg0) -> Complex
        | (BigDecimal arg0) -> Complex
        | (Complex arg0) -> Complex

  def +: (Integer arg0) -> Complex
       | (Float arg0) -> Complex
       | (Rational arg0) -> Complex
       | (BigDecimal arg0) -> Complex
       | (Complex arg0) -> Complex

  def +@: () -> Complex

  def -: (Integer arg0) -> Complex
       | (Float arg0) -> Complex
       | (Rational arg0) -> Complex
       | (BigDecimal arg0) -> Complex
       | (Complex arg0) -> Complex

  def -@: () -> Complex

  def /: (Integer arg0) -> Complex
       | (Float arg0) -> Complex
       | (Rational arg0) -> Complex
       | (BigDecimal arg0) -> Complex
       | (Complex arg0) -> Complex

  def ==: (Object arg0) -> bool

  # Returns the absolute part of its polar form.
  # 
  # ```ruby
  # Complex(-1).abs         #=> 1
  # Complex(3.0, -4.0).abs  #=> 5.0
  # ```
  def abs: () -> Numeric

  # Returns square of the absolute value.
  # 
  # ```ruby
  # Complex(-1).abs2         #=> 1
  # Complex(3.0, -4.0).abs2  #=> 25.0
  # ```
  def abs2: () -> Numeric

  # Returns the angle part of its polar form.
  # 
  # ```ruby
  # Complex.polar(3, Math::PI/2).arg  #=> 1.5707963267948966
  # ```
  def angle: () -> Float

  # Returns the angle part of its polar form.
  # 
  # ```ruby
  # Complex.polar(3, Math::PI/2).arg  #=> 1.5707963267948966
  # ```
  def arg: () -> Float

  def coerce: (Numeric arg0) -> [ Complex, Complex ]

  # Returns the complex conjugate.
  # 
  # ```ruby
  # Complex(1, 2).conjugate  #=> (1-2i)
  # ```
  def conj: () -> Complex

  # Returns the complex conjugate.
  # 
  # ```ruby
  # Complex(1, 2).conjugate  #=> (1-2i)
  # ```
  def conjugate: () -> Complex

  # Returns the denominator (lcm of both denominator - real and imag).
  # 
  # See numerator.
  def denominator: () -> Integer

  def eql?: (Object arg0) -> bool

  def equal?: (Object arg0) -> bool

  def fdiv: (Numeric arg0) -> Complex

  def hash: () -> Integer

  # Returns the imaginary part.
  # 
  # ```ruby
  # Complex(7).imaginary      #=> 0
  # Complex(9, -4).imaginary  #=> -4
  # ```
  def imag: () -> (Integer | Float | Rational | BigDecimal)

  # Returns the imaginary part.
  # 
  # ```ruby
  # Complex(7).imaginary      #=> 0
  # Complex(9, -4).imaginary  #=> -4
  # ```
  def imaginary: () -> (Integer | Float | Rational | BigDecimal)

  # Returns the value as a string for inspection.
  # 
  # ```ruby
  # Complex(2).inspect                       #=> "(2+0i)"
  # Complex('-8/6').inspect                  #=> "((-4/3)+0i)"
  # Complex('1/2i').inspect                  #=> "(0+(1/2)*i)"
  # Complex(0, Float::INFINITY).inspect      #=> "(0+Infinity*i)"
  # Complex(Float::NAN, Float::NAN).inspect  #=> "(NaN+NaN*i)"
  # ```
  def inspect: () -> String

  # Returns the absolute part of its polar form.
  # 
  # ```ruby
  # Complex(-1).abs         #=> 1
  # Complex(3.0, -4.0).abs  #=> 5.0
  # ```
  def magnitude: () -> (Integer | Float | Rational | BigDecimal)

  # Returns the numerator.
  # 
  # ```
  #     1   2       3+4i  <-  numerator
  #     - + -i  ->  ----
  #     2   3        6    <-  denominator
  # 
  # c = Complex('1/2+2/3i')  #=> ((1/2)+(2/3)*i)
  # n = c.numerator          #=> (3+4i)
  # d = c.denominator        #=> 6
  # n / d                    #=> ((1/2)+(2/3)*i)
  # Complex(Rational(n.real, d), Rational(n.imag, d))
  #                          #=> ((1/2)+(2/3)*i)
  # ```
  # 
  # See denominator.
  def numerator: () -> Complex

  # Returns the angle part of its polar form.
  # 
  # ```ruby
  # Complex.polar(3, Math::PI/2).arg  #=> 1.5707963267948966
  # ```
  def phase: () -> Float

  # Returns an array; \[cmp.abs, cmp.arg\].
  # 
  # ```ruby
  # Complex(1, 2).polar  #=> [2.23606797749979, 1.1071487177940904]
  # ```
  def polar: () -> [ Integer | Float | Rational | BigDecimal, Integer | Float | Rational | BigDecimal ]

  def quo: (Integer arg0) -> Complex
         | (Float arg0) -> Complex
         | (Rational arg0) -> Complex
         | (BigDecimal arg0) -> BigDecimal
         | (Complex arg0) -> Complex

  # Returns the value as a rational if possible (the imaginary part should
  # be exactly zero).
  # 
  # ```ruby
  # Complex(1.0/3, 0).rationalize  #=> (1/3)
  # Complex(1, 0.0).rationalize    # RangeError
  # Complex(1, 2).rationalize      # RangeError
  # ```
  # 
  # See to\_r.
  def rationalize: () -> Rational
                 | (?Numeric arg0) -> Rational

  # Returns the real part.
  # 
  # ```ruby
  # Complex(7).real      #=> 7
  # Complex(9, -4).real  #=> 9
  # ```
  def real: () -> (Integer | Float | Rational | BigDecimal)

  # Returns false.
  def real?: () -> FalseClass

  # Returns an array; \[cmp.real, cmp.imag\].
  # 
  # ```ruby
  # Complex(1, 2).rectangular  #=> [1, 2]
  # ```
  def rect: () -> [ Integer | Float | Rational | BigDecimal, Integer | Float | Rational | BigDecimal ]

  # Returns an array; \[cmp.real, cmp.imag\].
  # 
  # ```ruby
  # Complex(1, 2).rectangular  #=> [1, 2]
  # ```
  def rectangular: () -> [ Integer | Float | Rational | BigDecimal, Integer | Float | Rational | BigDecimal ]

  # Returns self.
  # 
  # ```ruby
  # Complex(2).to_c      #=> (2+0i)
  # Complex(-8, 6).to_c  #=> (-8+6i)
  # ```
  def to_c: () -> Complex

  # Returns the value as a float if possible (the imaginary part should be
  # exactly zero).
  # 
  # ```ruby
  # Complex(1, 0).to_f    #=> 1.0
  # Complex(1, 0.0).to_f  # RangeError
  # Complex(1, 2).to_f    # RangeError
  # ```
  def to_f: () -> Float

  # Returns the value as an integer if possible (the imaginary part should
  # be exactly zero).
  # 
  # ```ruby
  # Complex(1, 0).to_i    #=> 1
  # Complex(1, 0.0).to_i  # RangeError
  # Complex(1, 2).to_i    # RangeError
  # ```
  def to_i: () -> Integer

  # Returns the value as a rational if possible (the imaginary part should
  # be exactly zero).
  # 
  # ```ruby
  # Complex(1, 0).to_r    #=> (1/1)
  # Complex(1, 0.0).to_r  # RangeError
  # Complex(1, 2).to_r    # RangeError
  # ```
  # 
  # See rationalize.
  def to_r: () -> Rational

  # Returns the value as a string.
  # 
  # ```ruby
  # Complex(2).to_s                       #=> "2+0i"
  # Complex('-8/6').to_s                  #=> "-4/3+0i"
  # Complex('1/2i').to_s                  #=> "0+1/2i"
  # Complex(0, Float::INFINITY).to_s      #=> "0+Infinity*i"
  # Complex(Float::NAN, Float::NAN).to_s  #=> "NaN+NaN*i"
  # ```
  def to_s: () -> String

  def zero?: () -> bool
end

Complex::I: Complex
