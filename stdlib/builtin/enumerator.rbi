class Enumerator[A, B]
  include Enumerable[A, B]
  def each: { (A) -> void } -> B
  def with_object: [X] (X) { (A, X) -> void } -> X
  def with_index: { (A, Integer) -> void } -> B
                | -> Enumerator[[A, Integer], B]
end
