# Rust Crates

RBS provides two Rust crates:

- **`ruby-rbs-sys`** -- Low-level FFI bindings to the RBS C parser
- **`ruby-rbs`** -- High-level safe Rust API for parsing RBS signatures

Both crates are published to [crates.io](https://crates.io/) and are developed within the `rust/` directory of this repository.

## Vendored RBS Source

The Rust crates depend on the RBS C parser source code (`include/`, `src/`) and configuration (`config.yml`) from this repository. These files are vendored into each crate's `vendor/rbs/` directory, which is managed by Rake tasks and not tracked by git.

The file `rust/rbs_version` records which version of RBS the Rust crates are pinned to.

## Setup

After cloning the repository, set up the vendored source before building the Rust crates:

```bash
rake rust:rbs:sync       # Uses the pinned version from rust/rbs_version
```

Then build and test:

```bash
cd rust
cargo test
```

## Rake Tasks

### `rake rust:rbs:sync`

Copies the source files from the pinned version into each crate's `vendor/rbs/`. The copied files are made read-only to prevent accidental edits.

### `rake rust:rbs:pin[VERSION]`

Records a git tag in `rust/rbs_version`. For example:

```bash
rake rust:rbs:pin[v4.0.3]
```

### `rake rust:publish`

Publishes both crates to crates.io. This task:

1. Verifies `rust/rbs_version` is set
2. Verifies vendor directories contain real files (not symlinks)
3. Verifies the git working tree is clean
4. Temporarily commits the vendor files (reverted after publish)
5. Runs a dry-run to check packaging
6. Publishes `ruby-rbs-sys` first, then `ruby-rbs`

### `rake rust:rbs:symlink`

If your development needs unreleased version of RBS source code, use `rake rust:rbs:symlink` to set up symlinks in vendor directories to refer the worktree source code. Changes to the C parser source are immediately reflected in Rust builds.

## Publishing Workflow

1. Pin the RBS version to release against:

   ```bash
   rake rust:rbs:pin[v4.0.3]
   ```

2. Sync the vendored source:

   ```bash
   rake rust:rbs:sync
   ```

3. Update crate versions in `rust/ruby-rbs-sys/Cargo.toml` and `rust/ruby-rbs/Cargo.toml`.

4. Build and test:

   ```bash
   cd rust && cargo test
   ```

5. Commit the version changes and `rust/rbs_version`:

   ```bash
   git add rust/rbs_version rust/ruby-rbs-sys/Cargo.toml rust/ruby-rbs/Cargo.toml
   git commit -m "Bump Rust crate versions"
   ```

6. Publish:

   ```bash
   rake rust:publish
   ```
