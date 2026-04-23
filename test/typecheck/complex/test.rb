class Raises
  def to_c = fail
end

class RaisesNumeric < Numeric
  def to_c = fail
end

Complex(1) #: Complex
Complex(1.23) #: Complex
Complex(1r) #: Complex
Complex(1i) #: Complex
Complex(1ri) #: Complex
Complex(Numeric.new) #: Complex
Complex('1+2i') #: Complex

Complex(1, exception: true) #: Complex
Complex(1.23, exception: true) #: Complex
Complex(1r, exception: true) #: Complex
Complex(1i, exception: true) #: Complex
Complex(1ri, exception: true) #: Complex
Complex(Numeric.new, exception: true) #: Complex
Complex("1+2i", exception: true) #: Complex

Complex(Raises.new, exception: false) #: nil
Complex(RaisesNumeric.new, exception: false) #: nil
Complex('a', exception: false) #: nil

Complex(1, 1) #: Complex
Complex(1.23, 1.23) #: Complex
Complex(1r, 1r) #: Complex
Complex(1i, 1i) #: Complex
Complex(1ri, 1ri) #: Complex
Complex(Numeric.new, Numeric.new) #: Complex
Complex('1+2i', '1+2i') #: Complex
Complex(2, '1+2i') #: Complex

Complex(1, Raises.new, exception: false) #: nil
Complex(RaisesNumeric.new, 2, exception: false) #: nil
Complex('a', 3, exception: false) #: nil
Complex(2, :untyped, exception: false) #: nil
