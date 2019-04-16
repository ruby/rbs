class Pathname
  def self.glob: (Pathname, ?Integer) -> Array[Pathname]
  def `+`: (Pathname) -> Pathname
         | (String) -> Pathname
  def file?: -> bool
  def relative_path_from: (Pathname) -> Pathname
  def open: [X] (?String) { (IO) -> X } -> X
  def join: (String) -> self
  def realpath: -> self
  def directory?: -> bool
  def relative?: -> bool
  def cleanpath: -> self
  def read: -> String
  def mkpath: -> void
  def write: (String) -> void
  def sub_ext: (String) -> self
end

extension Kernel (Pathname)
  def Pathname: (String) -> Pathname
end
