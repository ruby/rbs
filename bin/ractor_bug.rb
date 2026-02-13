pp "RUBY_VERSION: #{RUBY_VERSION}"

class Foo
  def initialize(bar:)
    @bar = bar
  end
end

class Bar < Foo
  def initialize(bar:, baz: 123)
    super(bar: bar)
    # h = { bar: bar }
    # super(**h)
    @baz = baz
  end
end

ractors = 10000.times.map do
  Ractor.new do
    1000.times do
      Bar.new(bar: "test", baz: 456)
    end
  end
end

ractors.each { _1.join }
