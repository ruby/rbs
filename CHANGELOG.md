# CHANGELOG

## master

## 0.6.0 (2020-07-12)

* Signature update for `Logger`.
* Clean `Environment#inspect`. [#331](https://github.com/ruby/rbs/pull/331)
* Module self type syntax update. [#329](https://github.com/ruby/rbs/pull/329)
* Better validation. [#328](https://github.com/ruby/rbs/pull/328)
* Parser performance improvement. [#327](https://github.com/ruby/rbs/pull/327)
* Runtime type checking performance improvements with sampling [#323](https://github.com/ruby/rbs/pull/323)

## 0.5.0 (2020-07-04)

* Signature updates for `Mutex_m`, `IO`, and `Enumerable`.
* Syntax update. [#307](https://github.com/ruby/rbs/pull/307)
* AST command prints _absolute_ type names with file name filtering. [#312](https://github.com/ruby/rbs/pull/312)
* Improve CLI message. [#309](https://github.com/ruby/rbs/pull/309)

## 0.4.0 (2020-06-15)

* Signature update for `Fiber`, `Encoding`, and `Enumerator`.
* Fix syntax error for underscore and `!` `?` [#304](https://github.com/ruby/rbs/pull/304)
* Improved return type inference in `rbs prototype rb` [#303](https://github.com/ruby/rbs/pull/303)
* Skip anonymous modules/classes in `rbs prototype runtime` [#302](https://github.com/ruby/rbs/pull/302)
* Fix `--require-relative` option in `rbs prototype runtime` [#299](https://github.com/ruby/rbs/pull/299)
* Add JSON schema for `rbs ast` [#295](https://github.com/ruby/rbs/pull/295)

## 0.3.1 (2020-05-22)

* Fix constant resolution again [#289](https://github.com/ruby/rbs/pull/289)

## 0.3.0 (2020-05-20)

* Fix constant resolution [#288](https://github.com/ruby/rbs/pull/288)

## 0.2.0

* The first release of RBS gem.

## 0.1.0

* Version 0.1.0 is the original `rbs` gem and it is different software from RBS.
