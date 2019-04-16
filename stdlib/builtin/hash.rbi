class Hash[K,V]
  def `[]`: (K) -> V?
  def `[]=`: (K, V) -> V
  def size: -> Integer
  def transform_values: [X] { (V) -> X } -> Hash[K, X]
  def each_key: { (K) -> void } -> instance
              | -> Enumerator[K, self]
  def self.`[]`: [K, V] (Array[[K, V]]) -> Hash[K, V]
  def keys: () -> Array[K]
  def each: { ([K, V]) -> any } -> self
          | -> Enumerator[[K, V], self]
  def key?: (K) -> bool
  def merge: (Hash[K, V]) -> Hash[K, V]
  def delete: (K) -> V?
  def each_value: { (V) -> void } -> self
                | -> Enumerator[V, self]
  def empty?: -> bool

  include Enumerable[[K, V], self]
end
