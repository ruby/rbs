module Enumerable[A, B] : _Each[A, B]
  def all?: -> bool
          | { (A) -> any } -> bool
          | (any) -> bool

  def any?: -> bool
          | { (A) -> any } -> bool
          | (any) -> bool

  def chunk: { (A) -> any } -> Enumerator[A, self]

  def chunk_while: { (A, A) -> any } -> Enumerator[A, B]

  def collect: [X] { (A) -> X } -> Array[X]
             | [X] -> Enumerator[A, Array[X]]

  alias map collect
  
  def flat_map: [X] { (A) -> Array[X] } -> Array[X]
              | [X] -> Enumerator[A, Array[X]]

  def collect_concat: [X] { (A) -> Array[X] } -> Array[X]
                    | [X] -> Enumerator[A, Array[X]]

  def count: -> Integer
           | (any) -> Integer
           | { (A) -> any } -> Integer

  def cycle: (?Integer) -> Enumerator[A, nil]
           | (?Integer) { (A) -> any } -> nil

  def detect: (A) { (A) -> any } -> A
            | { (A) -> any } -> A?
            | -> Enumerator[A, A?]
            | (A) -> Enumerator[A, A]

  def find: (A) { (A) -> any } -> A
          | { (A) -> any } -> A?
          | -> Enumerator[A, A?]
          | (A) -> Enumerator[A, A]

  def drop: (Integer) -> Array[A]

  def drop_while: -> Enumerator[A, Array[A]]
                | { (A) -> any } -> Array[A]

  def each_cons: (Integer) -> Enumerator[Array[A], nil]
               | (Integer) { (Array[A]) -> any } -> nil

  def each_entry: -> Enumerator[A, self]
                | { (A) -> any } -> self

  def each_slice: (Integer) -> Enumerator[Array[A], nil]
                | (Integer) { (Array[A]) -> any } -> nil

  def each_with_index: { (A, Integer) -> any } -> self

  def each_with_object: [X] (X) { (A, X) -> any } -> X

  def to_a: -> Array[A]
  def entries: -> Array[A]

  def find_all: -> Enumerator[A, Array[A]]
              | { (A) -> any } -> Array[A]
  def select: -> Enumerator[A, Array[A]]
            | { (A) -> any } -> Array[A]
  alias filter select

  def find_index: (any) -> Integer?
                | { (A) -> any } -> Integer?
                | -> Enumerator[A, Integer?]

  def first: () -> A?
           | (Integer) -> Array[A]

  def grep: (any) -> Array[A]
          | [X] (any) { (A) -> X } -> Array[X]

  def grep_v: (any) -> Array[A]
            | [X] (any) { (A) -> X } -> Array[X]

  def group_by: [X] { (A) -> X } -> Hash[X, Array[A]]

  def member?: (any) -> bool
  def include?: (any) -> bool

  def inject: [X] (X) { (X, A) -> X } -> X
            | (Symbol) -> any
            | (any, Symbol) -> any
            | { (A, A) -> A } -> A


  def reduce: [X] (X) { (X, A) -> X } -> X
            | (Symbol) -> any
            | (any, Symbol) -> any
            | { (A, A) -> A } -> A

  def max: -> A?
         | (Integer) -> Array[A]
         | { (A, A) -> Integer } -> A?
         | (Integer) { (A, A) -> Integer } -> Array[A]

  def max_by: { (A, A) -> Integer } -> A?
            | (Integer) { (A, A) -> Integer } -> Array[A]

  def min: -> A?
         | (Integer) -> Array[A]
         | { (A, A) -> Integer } -> A?
         | (Integer) { (A, A) -> Integer } -> Array[A]

  def min_by: { (A, A) -> Integer } -> A?
            | (Integer) { (A, A) -> Integer } -> Array[A]

  def min_max: -> Array[A]
             | { (A, A) -> Integer } -> Array[A]

  def min_max_by: { (A, A) -> Integer } -> Array[A]

  def none?: -> bool
           | { (A) -> any } -> bool
           | (any) -> bool

  def one?: -> bool
          | { (A) -> any } -> bool
          | (any) -> bool

  def partition: { (A) -> any } -> Array[Array[A]]
               | -> Enumerator[A, Array[Array[A]]]

  def reject: { (A) -> any } -> Array[A]
            | -> Enumerator[A, Array[A]]

  def reverse_each: { (A) -> void } -> self
                  | -> Enumerator[A, self]

  def slice_after: (any) -> Enumerator[Array[A], nil]
                 | { (A) -> any } -> Enumerator[Array[A], nil]

  def slice_before: (any) -> Enumerator[Array[A], nil]
                  | { (A) -> any } -> Enumerator[Array[A], nil]

  def slice_when: { (A, A) -> any } -> Enumerator[Array[A], nil]

  def sort: -> Array[A]
          | { (A, A) -> Integer } -> Array[A]

  def sort_by: { (A) -> any } -> Array[A]
             | -> Enumerator[A, Array[A]]

  def sort_by!: { (A) -> any } -> self
              | -> Enumerator[A, self]

  def sum: () -> Numeric
         | (Numeric) -> Numeric
         | (any) -> any
         | (?any) { (A) -> any } -> any

  def take: (Integer) -> Array[A]

  def take_while: { (A) -> bool } -> Array[A]
                | -> Enumerator[A, Array[A]]

  def to_h: -> Hash[any, any]

  def uniq: -> Array[A]
          | { (A) -> any } -> Array[A]
end
