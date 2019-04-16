class Process::Status
  def &: (Integer) -> Integer
  def `>>`: (Integer) -> Integer
  def coredump: -> bool
  def exited?: -> bool
  def exitstatus: -> Integer?
  def pid: -> Integer
  def signaled?: -> bool
  def stopsig: -> Integer?
  def success?: -> bool
  def termsig: -> Integer?
  def to_i: -> Integer
  def to_int: -> Integer
end
