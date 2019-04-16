class File < IO
  def self.binread: (String) -> String
  def self.extname: (String) -> String
  def self.basename: (String) -> String
  def self.readable?: (String) -> bool
  def self.binwrite: (String, String) -> void
  def self.read: (String) -> String
               | (String, Integer?) -> String?
  def self.fnmatch: (String, String, Integer) -> bool
  def path: -> String
  def self.write: (String, String) -> void
  def self.chmod: (Integer, String) -> void
end
