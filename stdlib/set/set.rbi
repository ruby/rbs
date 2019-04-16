class Set[A]
  def self.`[]`: [X] (*X) -> Set[X]

  def initialize: (_Each[A, any]) -> any
                | [X] (_Each[X, any]) { (X) -> A } -> any
                | (?nil) -> any

  def intersection: (_Each[A, any]) -> self
  def &: (_Each[A, any]) -> self

  def union: (_Each[A, any]) -> self
  def `+`: (_Each[A, any]) -> self
  def `|`: (_Each[A, any]) -> self

  def difference: (_Each[A, any]) -> self
  def `-`: (_Each[A, any]) -> self

  def add: (A) -> self
  def `<<`: (A) -> self
  def add?: (A) -> self?

  def member?: (any) -> bool
  def include?: (any) -> bool

  def `^`: (_Each[A, any]) -> self

  def classify: [X] { (A) -> X } -> Hash[X, self]

  def clear: -> self

  def collect!: { (A) -> A } -> self
  alias map! collect!

  def delete: (any) -> self
  def delete?: (any) -> self?

  def delete_if: { (A) -> any } -> self
  def reject!: { (A) -> any } -> self

  def disjoint?: (self) -> bool

  def divide: { (A, A) -> any } -> Set[self]
            | { (A) -> any } -> Set[self]

  def each: { (A) -> void } -> self

  def empty?: -> bool

  def flatten: -> Set[any]

  def intersect?: -> bool

  def keep_if: { (A) -> any } -> self

  def size: -> Integer
  alias length size

  def merge: (_Each[A, any]) -> self

  def subset?: (self) -> bool
  def proper_subst?: (self) -> bool

  def superset?: (self) -> bool
  def proper_superset?: (self) -> bool

  def replace: (_Each[A, any]) -> self

  def reset: -> self

  def select!: { (A) -> any } -> self?

  def subtract: (_Each[A, any]) -> self

  def to_a: -> Array[A]

  include Enumerable[A, self]
end
