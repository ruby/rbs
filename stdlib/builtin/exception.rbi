class Exception
  def self.exception: (*any) -> instance
  def initialize: (?String?) -> void

  def backtrace: -> Array[String]
  def backtrace_locations: -> Array[any]
  def cause: -> Exception?
  def exception: -> self
               | (String) -> self
  def full_message: -> String
  def inspect: -> String
  def message: -> String
  def to_s: -> String
  def set_backtrace: (nil) -> nil
                   | (String) -> String
                   | (Array[String]) -> Array[String]
end
