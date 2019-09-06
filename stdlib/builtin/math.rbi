# The [Math](Math) module contains module functions
# for basic trigonometric and transcendental functions. See class
# [Float](https://ruby-doc.org/core-2.6.3/Float.html) for a list of
# constants that define Ruby's floating point accuracy.
# 
# Domains and codomains are given only for real (not complex) numbers.
module Math
  def self.acos: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.acosh: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.asin: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.asinh: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.atan: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.atan2: (Integer | Float | Rational | BigDecimal y, Integer | Float | Rational | BigDecimal x) -> Float

  def self.atanh: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.cbrt: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.cos: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.cosh: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.erf: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.erfc: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.exp: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.frexp: (Integer | Float | Rational | BigDecimal x) -> [ Integer | Float | Rational | BigDecimal, Integer | Float | Rational | BigDecimal ]

  def self.gamma: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.hypot: (Integer | Float | Rational | BigDecimal x, Integer | Float | Rational | BigDecimal y) -> Float

  def self.ldexp: (Integer | Float | Rational | BigDecimal fraction, Integer | Float | Rational | BigDecimal exponent) -> Float

  def self.lgamma: (Integer | Float | Rational | BigDecimal x) -> (Integer | Float)

  def self.log: (Integer | Float | Rational | BigDecimal x, ?Integer | Float | Rational | BigDecimal base) -> Float

  def self.log10: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.log2: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.sin: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.sinh: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.sqrt: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.tan: (Integer | Float | Rational | BigDecimal x) -> Float

  def self.tanh: (Integer | Float | Rational | BigDecimal x) -> Float
end

Math::E: Float

Math::PI: Float

class Math::DomainError < StandardError
end
