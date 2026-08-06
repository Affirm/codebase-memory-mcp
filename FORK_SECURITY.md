# Managed Fork Security Policy

This repository is an organization-controlled fork of
`DeusData/codebase-memory-mcp`. It must not be run against an internal
repository unless all controls below are present in the exact checked-out
revision.

## Source-only indexing

File discovery fails closed at `cbm_is_source_extension_allowed()`. Only the
hardcoded source-code extensions in `src/discover/discover.c` may be indexed.
Everything else is excluded before language detection or content-based
disambiguation, including configuration, documentation, data, credential,
infrastructure, shell, and extensionless files.

`.gitignore`, `.cbmignore`, and `extra_extensions` can narrow discovery but
cannot expand this allowlist. Any allowlist expansion requires review by the
fork security owner.

Secondary enrichment paths are subject to the same boundary. Package-manifest
mapping, path-alias loading, and incremental semantic manifest hashing cannot
open a disallowed file type to enrich the graph.

This is a data-minimization boundary, not a comprehensive DLP guarantee. An
approved source file can still contain a secret, and MCP query results can be
included in requests sent by the MCP client to its configured LLM provider.

## Pinned upstream base

`FORK_LOCK.json` is the source of truth for the reviewed upstream input.
It contains a full 40-character commit SHA; branch names and moving release
aliases are prohibited. Updating the pin requires reviewing the upstream diff,
re-running the source-allowlist tests, and approval from the fork security
owner.

Consumers must likewise install an approved fork revision by full commit SHA.
The current approved revision is the `approved_fork_commit` recorded in
`FORK_LOCK.json`. For a source checkout, use:

```sh
git checkout --detach 01ef52e21687eeb105c9dc32b438f681aa9bd828
test "$(git rev-parse HEAD)" = "01ef52e21687eeb105c9dc32b438f681aa9bd828"
```

Do not build or run if that verification fails. Do not install from the
upstream release channels or from either repository's floating `main`.

## Managed binary distribution

The fork is distributed only as reviewed binary archives built from the exact
`approved_fork_commit`. Every archive must be accompanied by a separately
recorded SHA-256 digest and build provenance. Consumers must verify both the
source commit and digest before installation.

Network installers, self-update, floating release aliases, download URL
overrides, and public package-manager wrappers are prohibited. The shell and
PowerShell installers operate only on the binary bundled beside them and fail
if that binary is absent. The `update` command fails closed; it never selects,
downloads, or installs another build.

The release workflow may publish the reviewed archives in this fork, but it
must not publish npm, PyPI, Go, Homebrew, Chocolatey, Scoop, Winget, AUR,
Glama, or MCP Registry wrappers. `scripts/ci/check-managed-distribution.sh`
enforces this boundary in CI.

## Owner

`@DanielDeng2024` owns this fork and is responsible for merging applicable
upstream security patches. The detailed responsibilities are recorded in
`MAINTAINERS.md`.
