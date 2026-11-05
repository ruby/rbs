# Steep cannot check a block-pass argument against an optional block, because the
# expected type becomes a union with `nil` (soutaro/steep#1207). Core signatures
# therefore spell out a blockless overload instead of using `?{ ... }`.

[1, 2, 3].sum(&:to_r)
[1, 2, 3].sum(0r, &:to_r)

[1, 2, 3].count(&:even?)

hash = { 1 => 2 } #: Hash[Integer, Integer]
hash.transform_keys!({ 1 => 3 }, &:itself)
