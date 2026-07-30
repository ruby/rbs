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

### 1. Prepare the release

Open a pull request that carries everything the release needs:

- `lib/rbs/version.rb` — set `RBS::VERSION` to the version being released.
- `Gemfile.lock` — run `bundle install` after the bump; the lockfile records the version too, and
  `rake release` refuses to run with a dirty working tree.
- `CHANGELOG.md` — add a section for the new version, directly under the `# CHANGELOG` heading.
  Sections are newest first.

Label the pull request `skip-changelog`. It carries no change of its own, and without the label it
shows up in the next release's list — that is why 4.1.0's changelog contains a `Version 4.1.0`
entry.

`rake gem:changelog` lists the pull requests merged since the last release, already formatted:

```console
$ bundle exec rake gem:changelog | pbcopy
```

It starts from the latest `v*` tag; pass a version to start somewhere else
(`rake 'gem:changelog[4.1.0]'`). Only the list goes to STDOUT, so it pipes cleanly. Pull requests
labeled `skip-changelog` are left out and reported on STDERR, and pull requests that only touch
`rust/` are left out because the crates have their own release cycle.

Sort the list into the sections below. `rake gem:changelog:json` prints the same pull requests with
the changed files, labels, and body of each, which is what the sorting is based on.

```markdown
## X.Y.Z (YYYY-MM-DD)

### Signature updates

### Language updates

### Library changes

#### rbs prototype

#### rbs collection

### Miscellaneous
```

The sections always appear in this order; delete the ones that end up empty, which is most of them
on a small release. Two things scale with the size of the release:

- **Summary paragraphs**, above the first section. A patch release usually has none, 4.1.0 has four
  paragraphs, and 4.0.0 has nine.
- **A list of the types whose signatures changed**, as the first line of `### Signature updates`,
  written as `**Updated classes/modules/methods:**` followed by the names in backticks. Used on
  `X.Y.0` releases only.

The date is the day the gem is released, matching the `vX.Y.Z` tag — not the day this pull request
is opened. Fix it up before step 2 if the pull request sat for a few days.

> While `.github/workflows/milestone.yml` is a required check, the release pull request needs a
> milestone matching the new version (`RBS X.Y` for a `.0` release, `RBS X.Y.x` otherwise). Create
> the milestone on GitHub first if the minor version changes.

### 2. Release the `ruby` gem

Once the release pull request is merged and `master` is checked out, run on CRuby:

```console
$ bundle exec rake release
```

This re-builds the `ruby`-platform gem and then:

- creates the tag `vX.Y.Z`,
- pushes the current branch and the tag to `origin`,
- pushes the gem to RubyGems,
- runs `release:note`, which opens a GitHub **draft** release (with
  `--prerelease` for `*.pre.*` versions) and prints the remaining manual steps.

### 3. Build and push the `java` gem

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

### 4. Start the next development cycle

Open another pull request setting `RBS::VERSION` to the next prerelease (`4.1.1` → `4.1.2.pre`),
with `Gemfile.lock` regenerated, labeled `skip-changelog` like the release pull request itself.
Without it the version on `master` keeps claiming to be the released version for the whole
development period — and, while the milestone check is in place, pull requests are checked against
the released version's milestone.

## Notes

- Prereleases (`X.Y.Z.pre.N`) are only installed with `gem install rbs --pre`;
  a plain `gem install rbs` is unaffected. On JRuby, `gem install rbs [--pre]`
  resolves to the `-java` gem automatically.
- The Dockerfile pins the WASI SDK / Chicory / ASM versions to match the
  `wasm` and `jruby` CI workflows. Keep them in sync when bumping.
