class Foo
  def self.singleton
  end

  private

  def private_method
  end
end

module Bar
  def self.singleton
  end
end

Foo.class_eval do
  singleton
end

Foo.new.instance_eval do
  private_method
end

Bar.module_eval do
  singleton
end
