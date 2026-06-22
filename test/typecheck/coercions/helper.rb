class MyCoerce
  def coerce(t)
    [MySelf.new, MyOther.new]
  end
end

class MyOther
end

class MySelf
  def +(o)
    MyReturn.new
  end
end

class MyReturn
end
