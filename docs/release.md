# Releasing RBS

A release is a pull request and one workflow run. Everything that leaves the
repository — the tag, both gems, and the GitHub release — is produced by the
`Release gems` workflow, so nothing has to be built or pushed from a laptop.

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

The release pull request in step 1 is merged by a person who has reviewed it. Its merge commit is
what step 2 dispatches, tags, and pushes to RubyGems, and none of that can be taken back — so
prepare that pull request and stop there, rather than merging it and carrying on to step 2.

The bump that starts a new minor is the only other pull request that sets `RBS::VERSION`. It
publishes nothing and another bump undoes it, so one opened on an explicit request can go through
on its own.

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

Both tasks reach GitHub through `gh`, which a Claude Code on the web session cannot do. See
[Assembling the changelog without `gh`](#assembling-the-changelog-without-gh), which runs them on a
runner instead.

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
  paragraphs, and 4.0.0 has nine. A prerelease has none whatever its size: the cycle it belongs to
  is summarized once, on the release proper that folds it in.
- **A list of the types whose signatures changed**, as the first line of `### Signature updates`,
  written as `**Updated classes/modules/methods:**` followed by the names in backticks. Used on
  `X.Y.0` releases only.

The date is the day the gem is released, matching the `vX.Y.Z` tag — not the day this pull request
is opened. Fix it up before step 2 if the pull request sat for a few days.

### 2. Run the `Release gems` workflow

Once the pull request is merged, dispatch
[`release-gems.yml`](../.github/workflows/release-gems.yml) from the Actions tab with two inputs:

| Input | Value |
| --- | --- |
| `commit` | The full 40-character SHA of the merge commit, taken from the merged pull request |
| `version` | `X.Y.Z`, without the leading `v` |

The ref selector picks which copy of the workflow file runs, not what gets released — leave it on
`master`. Everything is built from `commit`, so the run is unaffected by whatever lands on `master`
in the meantime, and a patch release cut from a release branch is dispatched the same way as any
other: the workflow does not care which branch the commit is on.

The two inputs say the same thing twice, once as a commit and once as a name, and the run stops
before anything is built unless they agree with each other and with the repository:

- `commit` has to be a full SHA that some branch contains,
- `version` has to be the `RBS::VERSION` that commit declares,
- CHANGELOG.md has to start with a section for `version` (skipped for `.dev.N`, which is not
  written up),
- `vX.Y.Z` must not exist yet.

It then:

- builds `rbs-X.Y.Z.gem`,
- compiles `rbs_parser.wasm` and builds `rbs-X.Y.Z-java.gem`,
- checks both: platforms, the C extension on one and its absence on the other, and that the wasm
  module made it into the `java` gem,
- installs the `java` gem on JRuby and parses with it, so the WebAssembly runtime is exercised
  before anything is published,
- uploads both gems as an artifact,
- tags `commit` as `vX.Y.Z` and pushes the tag,
- pushes both gems to RubyGems through trusted publishing,
- publishes the GitHub release with the notes from CHANGELOG.md, skipping this last step for
  `.dev.N` versions.

The tag is created once both gems are known to build and run, and before anything is published: a
tag can be deleted, while a version pushed to RubyGems can only be yanked.

Checking the `dry_run` box runs everything up to the artifact and stops — no tag, no gems pushed,
no release — which is how the build is exercised without releasing. `version` still has to match
the commit, so a dry run is also how a release is rehearsed before it is cut.

## The version on `master`

`RBS::VERSION` on `master` is read one of two ways, told apart by how the version ends:

| On `master` | Means |
| --- | --- |
| `X.Y.0.dev` — a bare `.dev` | `X.Y.0` is being developed |
| A complete version — `X.Y.Z`, `X.Y.Z.pre.N`, `X.Y.Z.dev.N` | The version *after* the one named is being developed |

So `4.1.1` on `master` is not a claim that `master` is 4.1.1. It says 4.1.1 has shipped and what
comes after it is being worked on. `4.1.2.dev.1` says the same thing about itself: that release is
out, and the line continues towards 4.1.2.

Both become true the moment the release is tagged, so **nothing has to be done to `master` after a
release**. `4.0.1` was followed by `4.0.2` with no version change in between, and `4.1.2.dev.1` is
what `master` carries today.

The bare `X.Y.0.dev` is the exception because it is the one version that names a target rather than
a predecessor: a new minor is developed towards `X.Y.0` for a long time, before it is known whether
the next thing to ship is `X.Y.0.pre.1` or `X.Y.0` itself. Setting it is the only version change
that has to be made deliberately.

`rake gem:changelog` reads `RBS::VERSION` too, to decide where the next changelog starts — but the
version is set to the one being released before the changelog is generated, so it sees that rather
than whatever `master` was carrying.

## Starting a new minor

`master` is the development line of one minor at a time. Moving it from `X.Y` to `X.(Y+1)` is not
part of any one release — it is the decision that the `X.Y` line is done, taken whenever that
becomes true — and it is the one moment the version on `master` is changed by hand. Two changes, in
opposite places:

1. **Branch the line being left behind**, from the last `master` commit that belongs to it:

   ```console
   $ git switch --create aaa-X.Y.x <that commit>
   $ git push -u origin aaa-X.Y.x
   ```

   Branch from the commit *before* the bump below, so the branch keeps the version its line was
   released under. Patch releases of `X.Y` are cut from here from now on, with their changes
   cherry-picked from `master` — see [Backports](#backports). The `aaa-` prefix carries no meaning
   beyond sorting the release branches to the top of the branch list.

   The branch carries its own release tooling, since that is read from the ref rather than from
   `master`: the `gem:` tasks, and `changelog.yml` for the changelog. Branching from `master`
   brings both along; what needs watching is a later change to either, which reaches this line
   only if it is cherry-picked here too.

2. **Bump `master`** to `X.(Y+1).0.dev`, in a pull request with `Gemfile.lock` regenerated and
   labeled `skip-changelog` like the release pull request itself. `4.1` was started exactly this
   way: `aaa-4.0.x` was branched at the commit before `Start 4.1 development`, which set
   `RBS::VERSION` to `4.1.0.dev`.

Two loose ends that are easy to forget:

- **The release note of the new line.** `rake gem:gh_release` links every published release to
  `https://github.com/ruby/rbs/wiki/Release-Note-X.Y`, built from the version number without
  checking that the page is there. Nothing has to be written when the line starts — the page comes
  together as the first release proper of the line comes into view — but it does have to exist by
  the time that release is published, or its notes link to an empty page.
- **Release branches that are done.** A branch is worth keeping only while its line might still
  get a patch. The ones that exist do not cover every line that ever had one — `3.8.1` shipped and
  there is no `aaa-3.8.x` — so this is housekeeping rather than a rule, but starting a new minor is
  the natural moment to look at the bottom of the branch list and delete what has been superseded.

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

The entry names that pull request and adds the one that carried the backport:

```markdown
* {title} ([#{original}](https://github.com/ruby/rbs/pull/{original}), Backported in [#{backport}](https://github.com/ruby/rbs/pull/{backport}))
```

`gem:changelog` prints this form on its own, from the same `-x` trailer: the origin it resolves is
the first link, and the pull request of the cherry-pick in front of it is the second. On the
development line nothing is a cherry-pick, so entries there keep the plain single link.

The second link is what keeps the entry from reading as a mistake. The original pull request is
against `master`, so it is listed again when the development line ships — and with nothing to tell
the two apart, the same link under two version headings looks like a change written into the wrong
section. #1923 is the pair to look at: plain under 3.6.0.pre.1, annotated under 3.5.2, which
backported it.

## Assembling the changelog without `gh`

`gem:changelog` and `gem:changelog:json` reach GitHub through `gh`, so they cannot run from a
Claude Code on the web session. `api.github.com` refuses anything the shell does there, and the
refusal is keyed on the session rather than on the client, so installing `gh` does not help:

```console
$ curl -s -o /dev/null -w '%{http_code}' https://api.github.com/repos/ruby/rbs
403
```

Nothing else about the release is affected. `gem:check_release` and `gem:tag` read git and the
working tree, `gem:gh_release` runs on a runner, and git itself reaches github.com normally —
clone, fetch and push all work.

So the task is run where it does work. Dispatch
[`changelog.yml`](../.github/workflows/changelog.yml), which runs it on a runner, and read the list
from the run summary, the log, or the `changelog` artifact.

| Input | Value |
| --- | --- |
| The ref selector | The branch the changelog is for: `aaa-X.Y.x` for a patch release, `master` otherwise |
| `version` | Where the changelog starts, when that should not follow `RBS::VERSION`. It names the release before the one being written, so `4.1.2` produces the 4.1.3 changelog |
| `format` | `list` for the template, `json` for the pull request details the sections are sorted from |

The ref is not incidental the way it is for `release-gems.yml`: it picks the history being
described *and* the copy of the task that describes it. So a release branch needs `changelog.yml`
on it, the same way it needs the release tasks — dispatching on a ref without the file fails with
`Workflow does not have 'workflow_dispatch' trigger`, since the trigger is read from the ref.

## Notes

- Prereleases (`X.Y.Z.pre.N`) are only installed with `gem install rbs --pre`;
  a plain `gem install rbs` is unaffected. On JRuby, `gem install rbs [--pre]`
  resolves to the `-java` gem automatically.
- The WASI SDK version is pinned in `wasm.yml`, `jruby.yml`, `release-gems.yml`, and
  `Dockerfile.jruby`, each carrying its own copy. Keep them in sync when bumping. The
  Chicory/ASM versions are not duplicated: they are the `jar` requirements in
  `rbs.gemspec`, which is where the workflow, `Dockerfile.jruby` and `gem install` all
  read them from.
- `rake 'gem:check_release[X.Y.Z]'` and `rake gem:tag` are what the workflow runs to
  check the release and to create the tag. Both work locally, which is the fallback
  if the tag ever has to be created by hand.
- Those two tasks and `rake gem:gh_release` come from the Rakefile of the commit
  being released, not from the branch the workflow was dispatched from. Releasing
  from a release branch (`aaa-X.Y.x`) therefore needs the release tooling on that
  branch as well; without it the run fails on the missing task, before publishing
  anything.
