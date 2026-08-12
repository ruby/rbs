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
[Assembling the changelog without `gh`](#assembling-the-changelog-without-gh) for how the same list
is produced there.

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

## Assembling the changelog without `gh`

A release can be prepared from a Claude Code on the web session, with one exception:
`gem:changelog` and `gem:changelog:json` cannot run there. Both go through `gh`, and in such a
session `api.github.com` is blocked at the agent proxy for anything the shell does. `gh` is not
installed, installing it does not help, and rewriting the tasks against REST or Net::HTTP would be
blocked the same way — the refusal is keyed on the session rather than on the client:

```console
$ curl -H "Authorization: Bearer $GH_TOKEN" https://api.github.com/repos/ruby/rbs
{"message":"GitHub access is not enabled for this session. ..."}   # HTTP 403
```

Nothing else in the release is affected. `gem:check_release` and `gem:tag` read git and the working
tree, and `gem:gh_release` runs on a runner, where `gh` and `github.token` both work.

What the session does have is the GitHub MCP server, which reaches the API through its own
credentials. The changelog is assembled with its tools, in the three steps the rake task takes.

**1. Where the changelog starts.** The rule is `changelog_base`: a prerelease starts from the
latest tag, a release proper skips the prerelease tags. Tags are not fetched by default.

```console
$ git fetch origin --tags
$ git describe --tags --match 'v*' --abbrev=0 --exclude 'v*.pre*' --exclude 'v*.dev*'
v4.1.1
```

Drop the two `--exclude` flags for a prerelease, which starts at the latest tag whatever it is.

**2. The commits.**

```console
$ git log --format=%H v4.1.1..HEAD
```

**3. The pull requests they came from.** List the merged pull requests with `list_pull_requests`
(`base: master`, `state: closed`, `sort: updated`, `direction: desc`, and `fields: number, title,
labels, merged_at, head`), paging back until `merged_at` predates the base tag, and keep the ones
whose `head.sha` appears in the commit list from step 2. That intersection is what the task's
GraphQL `associatedPullRequests` query answers, reached from the other side.

Then drop the pull requests labeled `skip-changelog` and format the rest newest first, which is the
order of step 2:

```markdown
* {title} ([#{number}](https://github.com/ruby/rbs/pull/{number}))
```

Sorting them into sections needs the changed files, which `gem:changelog:json` would have supplied:
`pull_request_read` with `get_files` per pull request, or `get` for the body.

Four things about that matching, the first of which is a trap:

- **Do not read the numbers from `Merge pull request #N` commit subjects.** It looks like it works
  on this repository, and it silently loses pull requests. Applying the path filter the task uses
  (`git log --full-history --simplify-merges -- . ':(exclude)rust'`) drops the merge commits while
  keeping the commits they merged, so on the 4.1.2 cycle five of the eight numbers disappeared with
  them. A squashed or rebased pull request never writes that subject at all. Matching `head.sha`
  has neither failure mode.
- `head.sha` is in the history because this repository merges pull requests with merge commits. A
  squashed or rebased one would need its `merge_commit_sha`, which the listing does not carry.
- The listing reports `merged: false` for pull requests that are merged — the field is not
  populated by that endpoint. Read `merged_at` instead.
- On a release branch the commits are cherry-picks, so resolve the `(cherry picked from commit
  <sha>)` trailer first and match the recorded origin, as `changelog_origins` does. Matching the
  cherry-pick itself attributes every backport to the pull request that carried it.

Pull requests confined to `rust/` are left out too, which the task does by filtering the commits in
step 2 with `-- . ':(exclude)rust'`. Leave step 2 unfiltered here and drop those pull requests by
their `get_files` instead. The filter decides which commits are listed, and a pull request is found
by one specific commit — its head — so a pull request whose last commit happens to touch only
`rust/` would lose that head and disappear even though the rest of it belongs in the changelog.
Matching against every commit and filtering afterwards cannot go wrong that way.

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
