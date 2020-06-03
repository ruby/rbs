# RBS

RBS provides syntax and semantics definition for the `Ruby Signature` language, `.rbs` files.
It consists of a parser, the syntax, and class definition interpreter, the semantics.

## Build

We haven't published a gem yet.
You need to install the dependencies, and build its parser with `bin/setup`.

```
$ bin/setup
$ bundle exec exe/rbs
```

## Usage

```
$ rbs list
$ rbs ancestors ::Object
$ rbs methods ::Object
$ rbs method ::Object tap
```

### rbs list [--class|--module|--interface]

```
$ rbs list
```

This command lists all of the classes/modules/interfaces defined in `.rbs` files.

### rbs ancestors [--singleton|--instance] CLASS

```
$ rbs ancestors Array                    # ([].class.ancestors)
$ rbs ancestors --singleton Array        # (Array.class.ancestors)
```

This command prints the _ancestors_ of the class.
The name of the command is borrowed from `Class#ancestors`, but the semantics is a bit different.
The `ancestors` command is more precise (I believe).

### rbs methods [--singleton|--instance] CLASS

```
$ rbs methods ::Integer                  # 1.methods
$ rbs methods --singleton ::Object       # Object.methods
```

This command prints all methods provided for the class.

### rbs method [--singleton|--instance] CLASS METHOD

```
$ rbs method ::Integer '+'               # 1+2
$ rbs method --singleton ::Object tap    # Object.tap { ... }
```

This command prints type and properties of the method.

### Options

It accepts two global options, `-r` and `-I`.

`-r` is for libraries. You can specify the names of libraries.

```
$ rbs -r set list
```

`-I` is for application signatures. You can specify the name of directory.

```
$ rbs -I sig list
```

## Guides

- [Standard library signature contribution guide](docs/CONTRIBUTING.md)
- [Writing signatures guide](docs/sigs.md)
- [Stdlib signatures guide](docs/stdlib.md)
- [Syntax](docs/syntax.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/rbs.
