require_relative "test_helper"

class IntegerTest < StdlibTest
  target Integer
  using hook.refinement

  def test_to_s
    1.to_s
    1.to_s(2)
    1.to_s(3)
    1.to_s(4)
    1.to_s(5)
    1.to_s(6)
    1.to_s(7)
    1.to_s(8)
    1.to_s(9)
    1.to_s(10)
    1.to_s(11)
    1.to_s(12)
    1.to_s(13)
    1.to_s(14)
    1.to_s(15)
    1.to_s(16)
    1.to_s(17)
    1.to_s(18)
    1.to_s(19)
    1.to_s(20)
    1.to_s(21)
    1.to_s(22)
    1.to_s(23)
    1.to_s(24)
    1.to_s(25)
    1.to_s(26)
    1.to_s(27)
    1.to_s(28)
    1.to_s(29)
    1.to_s(30)
    1.to_s(31)
    1.to_s(32)
    1.to_s(33)
    1.to_s(34)
    1.to_s(35)
    1.to_s(36)
  end

  def test_digits
    1.digits
    1.digits(2)
  end

  def test_allbits?
    1.allbits?(1)
    2.allbits?(1)
  end

  def test_anybits?
    0xf0.anybits?(0xf)
    0xf1.anybits?(0xf)
  end

  def test_nobits?
    0xf0.nobits?(0xf)
    0xf1.nobits?(0xf)
  end
end
