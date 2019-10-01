class HashTest < StdlibTest
  target Hash
  using hook.refinement

  def test_each
    h = { a: 123 }

    h.each do |k, v|
      # nop
    end

    h.each do |x|
      # nop
    end

    h.each.each do |x, y|
      #
    end
  end
end
