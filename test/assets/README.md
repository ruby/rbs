# test/assets

This directory contains rubygems that is used for test of RBS.

## Test scenario 1

* [rbs-s1-amber](s1-test-gem)

**Test** RBS files in `sig` directory of a gem is loaded.

## Test scenario 2

* [rbs-s2-load_implicit](s2-load_implicit)

**Test** RBS files of a gem is not loaded when:

1. The gem has `sig/manifest.yaml` and `load_implicitly: false`, and
2. It is implicitly loaded via Bundler context

## Test scenario 3

* [rbs-s3-load_implicit](s3-load_implicit)
* [rbs-s3-load_transitive](s3-load_transitive)

**Test** RBS files of a gem with `load_implicitly: false` is loaded when it is a dependency of other loaded gems.
