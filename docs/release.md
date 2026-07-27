# Releasing RBS

Each release ships **two gems**:

| Gem | Platform | Parser | How it is built |
| --- | --- | --- | --- |
| `rbs-X.Y.Z.gem` | `ruby` (MRI) | C extension | `rake release` (re-builds it) |
| `rbs-X.Y.Z-java.gem` | `java` (JRuby) | WebAssembly (`lib/rbs/wasm`) | Docker image, pushed manually |

The `-java` gem contains no native code — just `rbs_parser.wasm`. The Chicory/ASM
jars it needs are not shipped in the gem; they are declared as `jar-dependencies`
requirements and fetched from Maven when the gem is installed. So the gem can be
built once in any environment and runs on every JRuby.

## Prerequisites

- Push rights to the `rbs` gem on RubyGems (`gem signin`). If your account has
  MFA enabled, `gem push` / `rake release` will prompt for an OTP.
- Docker, for the `-java` gem. The WASI SDK is baked into the image, so there is
  nothing to install on the host.

## Steps

### 1. Release the `ruby` gem

Once the version is bumped and committed, run on CRuby:

```console
$ bundle exec rake release
```

This re-builds the `ruby`-platform gem and then:

- creates the tag `vX.Y.Z`,
- pushes the current branch and the tag to `origin`,
- pushes the gem to RubyGems,
- runs `release:note`, which opens a GitHub **draft** release (with
  `--prerelease` for `*.pre.*` versions) and prints the remaining manual steps.

### 2. Build and push the `java` gem

The `java` gem is not built by `rake release`, so build and push it manually:

```console
# Build from the committed state (the gemspec's file list comes from `git ls-files`).
$ docker build -f Dockerfile.jruby -t rbs-jruby .

# Build rbs_parser.wasm and the -java gem into ./pkg on the host. The Chicory/ASM
# jars are not bundled; they are fetched from Maven when the gem is installed.
$ docker run --rm -e RBS_PLATFORM=java -v "$PWD/pkg:/out" rbs-jruby \
    gem build rbs.gemspec -o /out/rbs-X.Y.Z-java.gem

$ gem push pkg/rbs-X.Y.Z-java.gem
```

Optionally confirm it installs and runs on JRuby before pushing:

```console
$ docker run --rm -v "$PWD/pkg:/pkg" -w /tmp rbs-jruby bash -c \
    'gem install /pkg/rbs-X.Y.Z-java.gem && ruby -e "require %q{rbs}; puts [RUBY_ENGINE, RBS::VERSION].join(%q{ })"'
```

## Notes

- Prereleases (`X.Y.Z.pre.N`) are only installed with `gem install rbs --pre`;
  a plain `gem install rbs` is unaffected. On JRuby, `gem install rbs [--pre]`
  resolves to the `-java` gem automatically.
- The Dockerfile pins the WASI SDK / Chicory / ASM versions to match the
  `wasm` and `jruby` CI workflows. Keep them in sync when bumping.
