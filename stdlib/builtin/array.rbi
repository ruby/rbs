class Array[A]
  include Enumerable[A, self]

  def initialize: (?Integer, ?A) -> void
                | (self) -> void
                | (Integer) { (Integer) -> A } -> void

  def `*`: (Integer) -> self
         | (String) -> String
  def `-`: (self) -> self
  def difference: (self) -> self
  def `+`: (self) -> self
  def `|`: (self) -> self
  def union: (self) -> self
  def `&`: (self) -> self
  def `<<`: (A) -> self

  def `[]`: (Integer) -> A
          | (Range[Integer]) -> self?
          | (0, Integer) -> self
          | (Integer, Integer) -> self?
  def at: (Integer) -> A
        | (Range[Integer]) -> self?
        | (Integer, Integer) -> self?
  def `[]=`: (Integer, A) -> A
           | (Integer, Integer, A) -> A
           | (Integer, Integer, self) -> self
           | (Range[Integer], A) -> A
           | (Range[Integer], self) -> self

  def push: (*A) -> self
  def append: (*A) -> self

  def clear: -> self

  def collect!: { (A) -> A } -> self
              | -> Enumerator[A, self]
  def map!: { (A) -> A } -> self
          | -> Enumerator[A, self]

  def combination: (?Integer) { (self) -> any } -> Array[self]
                 | (?Integer) -> Enumerator[self, Array[self]]

  def empty?: -> bool
  def compact: -> self
  def compact!: -> self?
  def concat: (*Array[A]) -> self
            | (*A) -> self
  def delete: (A) -> A?
            | [X] (A) { () -> X } -> (A | X)
  def delete_at: (Integer) -> A?
  def delete_if: { (A) -> any } -> self
               | -> Enumerator[A, self]
  def reject!: { (A) -> any } -> self?
             | -> Enumerator[A, self?]
  def dig: (Integer, *any) -> any
  def each: { (A) -> any } -> self
          | -> Enumerator[A, self]
  def each_index: { (Integer) -> any } -> self
                | -> Enumerator[Integer, self]
  def fetch: (Integer) -> A
           | (Integer, A) -> A
           | (Integer) { (Integer) -> A } -> A
  def fill: (A) -> self
          | { (Integer) -> A } -> self
          | (A, Integer, ?Integer?) -> self
          | (A, Range[Integer]) -> self
          | (Integer, ?Integer?) { (Integer) -> A} -> self
          | (Range[Integer]) { (Integer) -> A } -> self

  def find_index: (A) -> Integer?
                | { (A) -> any } -> Integer?
                | -> Enumerator[A, Integer?]

  def index: (A) -> Integer?
           | { (A) -> any } -> Integer?
           | -> Enumerator[A, Integer?]

  def flatten: (?Integer?) -> Array[any]
  def flatten!: (?Integer?) -> self?

  def insert: (Integer, *A) -> self

  def join: (any) -> String

  def keep_if: { (A) -> any } -> self
             | -> Enumerator[A, self]

  def last: -> A?
          | (Integer) -> self

  def length: -> Integer
  def size: -> Integer

  def pack: (String, ?buffer: String) -> String

  def permutation: (?Integer) { (self) -> any } -> self
                 | (?Integer) -> Enumerator[self, self]

  def pop: -> A?
         | (Integer) -> self

  def unshift: (*A) -> self
  def prepend: (*A) -> self

  def product: (*Array[A]) -> Array[Array[A]]
             | (*Array[A]) { (Array[A]) -> any } -> self

  def assoc: (any) -> any
  def rassoc: (any) -> any

  def repeated_combination: (Integer) { (self) -> any } -> self
                          | (Integer) -> Enumerator[self, self]

  def repeated_permutation: (Integer) { (self) -> any } -> self
                          | (Integer) -> Enumerator[self, self]

  def replace: (self) -> self

  def reverse: -> self
  def reverse!: -> self
  def reverse_each: { (A) -> any } -> self
                  | -> Enumerator[A, self]

  def rindex: (A) -> Integer?
            | { (A) -> any } -> Integer?
            | -> Enumerator[A, Integer?]

  def rotate: (?Integer) -> self

  def rotate!: (?Integer) -> self

  def sample: (?random: any) -> A?
            | (Integer, ?random: any) -> self

  def select!: -> Enumerator[A, self]
             | { (A) -> any } -> self
  def filter!: -> Enumerator[A, self]
             | { (A) -> any } -> self

  def shift: -> A?
           | (Integer) -> self

  def shuffle: (?random: any) -> self

  def shuffle!: (?random: any) -> self

  def slice: (Integer) -> A?
           | (Integer, Integer) -> self?
           | (Range[Integer]) -> self?

  def slice!: (Integer) -> A?
            | (Integer, Integer) -> self?
            | (Range[Integer]) -> self?

  def to_a: -> self
  def to_ary: -> self
  def to_h: -> Hash[any, any]

  def transpose: -> self

  def uniq!: -> self?
           | { (A) -> any } -> self?

  def values_at: (*Integer | Range[Integer]) -> self

  def zip: [X] (Array[X]) -> Array[[A, X]]
         | [X] (Array[X]) { (A, X) -> any } -> nil

  def bsearch: { (A) -> any } -> A?
  def bsearch_index : { (A) -> any } -> Integer?
end
