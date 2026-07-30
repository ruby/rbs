# Releasing RBS

A release is a pull request, a tag, and one workflow run. Everything that leaves
the repository — both gems and the GitHub release — is produced by the `Release
gems` workflow, so nothing has to be built or pushed from a laptop.

Each release ships **two gems**:

| Gem | Platform | Parser |
| --- | --- | --- |
| `rbs-X.Y.Z.gem` | `ruby` (MRI) | C extension, compiled on install |
| `rbs-X.Y.Z-java.gem` | `java` (JRuby) | `rbs_parser.wasm`, built by the workflow |

The `-java` gem contains no native code — just `rbs_parser.wasm`. The Chicory/ASM
jars it needs are not shipped in the gem; they are declared as `jar-dependencies`
requirements and fetched from Maven when the gem is installed. So the gem can be
built once in any environment and runs on every JRuby.

There are three kinds of release, and they differ in what gets written up:

| Version | CHANGELOG section | GitHub release |
| --- | --- | --- |
| `X.Y.Z` | The whole cycle since the previous release proper, prereleases included | Published |
| `X.Y.Z.pre.N` | What changed since `X.Y.Z.pre.N-1` | Published, marked as a prerelease |
| `X.Y.Z.dev.N` | None | None |

`.dev.N` releases are cut from the development line for people who need a change
early, so they are gems and tags and nothing else.

## Prerequisites

Push rights to the `rbs` gem on RubyGems are **not** needed: the workflow
authenticates through a trusted publisher registered for this repository and
`release-gems.yml`. What is needed is write access to the repository, since that
is what lets you dispatch the workflow.

## Steps

### 1. Prepare the release

Open a pull request that carries everything the release needs:

- `lib/rbs/version.rb` — set `RBS::VERSION` to the version being released.
- `Gemfile.lock` — run `bundle install` after the bump; the lockfile records the version too.
- `CHANGELOG.md` — add a section for the new version, directly under the `# CHANGELOG` heading.
  Sections are newest first.

Label the pull request `skip-changelog`. It carries no change of its own, and without the label it
shows up in the next release's list — that is why 4.1.0's changelog contains a `Version 4.1.0`
entry.

`rake gem:changelog` lists the pull requests merged since the last release, already formatted:

```console
$ bundle exec rake gem:changelog | pbcopy
```

Where it starts follows `RBS::VERSION`, so bump the version first: a prerelease starts from the
latest tag, and a release proper skips the prerelease tags and starts from the previous release
proper. Pass a version to override it (`rake 'gem:changelog[4.1.0]'`). Only the list goes to
STDOUT, so it pipes cleanly. Pull requests labeled `skip-changelog` are left out and reported on
STDERR, and pull requests that only touch `rust/` are left out because the crates have their own
release cycle.

On a release proper, the `X.Y.Z.pre.N` sections above the previous release are replaced by the one
section being written — their pull requests are in it, and the notes they were published with stay
on their own GitHub releases.

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

### 2. Tag the release

Once the pull request is merged, tag the merge commit and push the tag:

```console
$ git switch master && git pull
$ git tag "v$(ruby -e 'load "lib/rbs/version.rb"; print RBS::VERSION')"
$ git push origin --tags
```

The tag comes before anything is published, so that the gems and the release notes describe a
commit that is already immutable — and because a tag can be deleted, while a version pushed to
RubyGems can only be yanked.

### 3. Run the `Release gems` workflow against the tag

Dispatch [`release-gems.yml`](../.github/workflows/release-gems.yml) from the Actions tab, picking
the `vX.Y.Z` tag — **not** a branch — in the ref selector. The trusted publisher has no branch
condition, so the ref you pick is what decides what gets published; the workflow refuses to run
unless the tag matches `RBS::VERSION`.

It then:

- builds `rbs-X.Y.Z.gem`,
- compiles `rbs_parser.wasm` and builds `rbs-X.Y.Z-java.gem`,
- checks both: platforms, the C extension on one and its absence on the other, and that the wasm
  module made it into the `java` gem,
- installs the `java` gem on JRuby and parses with it, so the WebAssembly runtime is exercised
  before anything is published,
- uploads both gems as an artifact,
- pushes both to RubyGems through trusted publishing,
- publishes the GitHub release with the notes from CHANGELOG.md, skipping this last step for
  `.dev.N` versions.

Dispatching against a branch runs everything up to the artifact and stops, which is how the build
is exercised without releasing.

### 4. Start the next development cycle

Open another pull request setting `RBS::VERSION` to the next prerelease (`4.1.1` → `4.1.2.pre`),
with `Gemfile.lock` regenerated, labeled `skip-changelog` like the release pull request itself.
Without it the version on `master` keeps claiming to be the released version for the whole
development period, and `rake gem:changelog` reads that version to decide where the next changelog
starts.

## Backports

A patch release is cut from a release branch (`aaa-X.Y.x`), and what it carries beyond the previous
release is cherry-picked from the development line. Cherry-pick with `-x`:

```console
$ git cherry-pick -x <commit>
```

`-x` records the commit the change was copied from, and that recorded line is what `rake
gem:changelog` follows to reach the pull request the change was written and reviewed in. Without
it, the only pull request a backported commit is associated with is the one that carried the
backport, which says nothing about the change and is the same for every commit it brought over —
that is why the 4.0.3 changelog credits its three entries to the same pull request.

## Notes

- Prereleases (`X.Y.Z.pre.N`) are only installed with `gem install rbs --pre`;
  a plain `gem install rbs` is unaffected. On JRuby, `gem install rbs [--pre]`
  resolves to the `-java` gem automatically.
- `Dockerfile.jruby` pins the WASI SDK / Chicory / ASM versions to match the
  `wasm`, `jruby`, and `release-gems` workflows. Keep them in sync when bumping.
