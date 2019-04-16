class Module
  def class: -> any
  def module_function: (*String | Symbol) -> self
  def attr_reader: (*String | Symbol) -> void
  def attr_accessor: (*String | Symbol) -> void
  def attr_writer: (*String | Symbol) -> void
  def extend: (Module, *Module) -> self
  def include: (Module, *Module) -> self
  def prepend: (Module, *Module) -> self
  def private: (*String | Symbol) -> void
  def public: (*String | Symbol) -> void
end
