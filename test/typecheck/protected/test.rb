class Account
  def initialize(name, balance)
    @name = name
    @balance = balance
    @pin = 0
  end

  def name
    @name
  end

  protected def balance
    @balance
  end

  protected def pin
    @pin
  end

  protected def pin=(value)
    @pin = value
  end

  protected

  # Demonstrates accessing protected state on another instance of the same class.
  def transfer_to(other, amount)
    return if balance < amount

    @balance -= amount
    other.instance_variable_set(:@balance, other.balance + amount)
  end
end

class CheckingAccount < Account
  # Demonstrates accessing protected state on another instance from a subclass.
  def richer_than?(other)
    balance > other.balance
  end
end

a = Account.new("alice", 100)
b = Account.new("bob", 50)

a.transfer_to(b, 25)

c = CheckingAccount.new("carol", 200)
d = CheckingAccount.new("dave", 75)

c.richer_than?(d)

# Reading a public attr_reader still works.
a.name
