# CI workflow

How [`.github/workflows/main.yml`](../.github/workflows/main.yml) builds and publishes the
`ohmyzsh/zsh` and `ohmyzsh/ohmyzsh` images.

## Overview

Image builds are delegated to [`docker/github-builder`][github-builder], a Docker-maintained
reusable workflow. This repository owns *when* and *what* to build; the reusable workflow owns
*how*. Build definitions live in [`docker-bake.hcl`](../docker-bake.hcl).

The workflow is pinned to `bake.yml@a492c6d04fd3315f67230809b44d60cc0acd50b3` (v1.16.0).

## Triggers and scope

Each build call expands into five GitHub jobs, of which only two build anything. The other three
(`registry-identities`, `prepare`, `finalize`) are fixed scaffolding that `bake.yml` spends per
call, and `prepare` alone takes about as long as a build. That overhead cannot be amortised: the
reusable workflow builds exactly one target and fans out only over platforms, so N versions always
cost N calls. Scope is therefore managed by limiting how many versions each event builds.

| Trigger | Zsh versions built | Historical OMZ versions | Pushes to Docker Hub | Approx. jobs |
| --- | --- | --- | --- | --- |
| `workflow_dispatch` | all 38 | all upstream tags | yes | ~380 |
| `push` to `main` | all 38 | none | yes | ~380 |
| `pull_request` | `master`, `5.9.2`, `4.3.11` | none | no | ~30 |
| `repository_dispatch` (`omz-release`) | none | the released tag | yes | ~5 |

There is no scheduled run. Rebuilds are driven by the two things that actually invalidate an
image:

- **The Debian base image.** Both `FROM` lines in [`zsh/Dockerfile`](../zsh/Dockerfile) pin
  `debian:trixie-slim` by digest, and `docker` is enabled in
  [`dependabot.yml`](../.github/dependabot.yml) for `/zsh`. Dependabot opens a pull request when
  the digest moves; merging it is a push to `main`, which rebuilds all 38 versions. A `push` must
  build the full matrix for exactly this reason — a base-image bump invalidates every version, not
  just the newest.
- **An Oh My Zsh release.** `repository_dispatch` with type `omz-release`, sent from
  `ohmyzsh/ohmyzsh`, builds the newly released tag against the latest Zsh. The Zsh layer beneath it
  is untouched, so the `zsh` and `omz-latest` jobs are skipped.

Debian republishes `trixie-slim` roughly every three weeks (measured over the last year: ~19 days
mean, never more than 22), so a weekly Dependabot check never misses a snapshot, and the result is
about 17–20 full rebuilds a year instead of 52 partial ones. Dependabot applies a default 3-day
cooldown before proposing a new digest.

Tradeoffs:

- Nothing rebuilds between snapshots, so an APT security update published inside a snapshot window
  is not picked up until the next Debian snapshot or a manual `workflow_dispatch`.
- Every merge to `main` now costs a full rebuild, including documentation-only merges. That is the
  price of not having to decide, per commit, whether a change affects all versions.

### Sending the release event

Dependabot has no equivalent for upstream Git tags, so `ohmyzsh/ohmyzsh` has to send the event. Add
a workflow there that fires on `release: published`:

```yaml
- run: |
    gh api repos/ohmyzsh/docker/dispatches \
      --field event_type=omz-release \
      --field 'client_payload[tag]=${{ github.event.release.tag_name }}'
  env:
    GH_TOKEN: ${{ secrets.OHMYZSH_DOCKER_DISPATCH_TOKEN }}
```

The token needs `contents: write` on `ohmyzsh/docker`. A payload without a `tag` falls back to
rebuilding every upstream tag.

**`ohmyzsh/ohmyzsh` currently has no git tags**, so this path is dormant until releases resume —
the same reason `omz-versions` always skips today.

The workflow does not run in forks: the `prepare` job carries
`if: github.repository == 'ohmyzsh/docker'`, and every other job depends on it. Comment that line
out to exercise the workflow in a fork. Pull requests *from* forks against this repository still
run, because they execute in this repository's context.

## Job graph

```
prepare ──> zsh ──> omz-latest ──> omz-versions ──> update-image-readme
```

`omz-versions` runs strictly after `omz-latest` rather than alongside it — see the Docker Hub
429 entry in Known quirks for why.

| Job | Purpose |
| --- | --- |
| `prepare` | Resolves the event-dependent build matrices and shared constants |
| `zsh` | Builds and publishes `ohmyzsh/zsh`, one reusable-workflow call per version |
| `omz-latest` | Builds latest Oh My Zsh against every Zsh version |
| `omz-versions` | Builds each historical OMZ tag against the latest Zsh |
| `update-image-readme` | Pushes image `README.md` files to Docker Hub as repository descriptions |

Jobs whose matrix resolves to `[]` are skipped, so which of these run depends on the event.

### `prepare`

Reusable-workflow `with:` inputs cannot read the `env` context, so values that would normally sit
in a workflow-level `env:` block are published as job outputs instead:

| Output | Example |
| --- | --- |
| `zsh_versions` | `["master","5.9.2","4.3.11"]` (JSON, event-dependent) |
| `omz_versions` | `[]` |
| `latest_zsh` | `5.9.2` |
| `latest_omz` | `master` |
| `zsh_image` | `ohmyzsh/zsh` |
| `omz_image` | `ohmyzsh/ohmyzsh` |

The Zsh version list is inline in this job's script. Adding a version there is all that is needed
to start publishing it.

`omz_versions` comes from the upstream tag list, except on `repository_dispatch`, where it is just
the released tag from `client_payload.tag`. **`ohmyzsh/ohmyzsh` currently has no git tags**, so on
every other event this is `[]` and `omz-versions` always skips — the job exists for when tags
reappear.

When `zsh_versions` is `[]` the `zsh` and `omz-latest` jobs skip, so `omz-versions` and
`update-image-readme` treat a skipped upstream job as success.

## Bake targets

[`docker-bake.hcl`](../docker-bake.hcl) defines two targets driven by five variables, which the
workflow passes through the `vars:` input (github-builder exposes them as environment variables,
which HCL `variable` blocks read).

| Variable | Purpose |
| --- | --- |
| `ZSH_VERSION` | Git ref to build; `master` or `zsh-<version>` |
| `OMZ_VERSION` | Oh My Zsh branch or tag |
| `ZSH_BASE_IMAGE` | Base image ref for the `ohmyzsh` target |
| `LINK_ZSH` | `true` resolves `ZSH_BASE_IMAGE` from the `zsh` target instead of the registry |
| `PLATFORMS` | Defaults to `linux/amd64,linux/arm64` |

`LINK_ZSH` is the mechanism that lets pull requests validate Oh My Zsh against the Zsh built in
that same pull request:

```hcl
contexts = LINK_ZSH == "true" ? { (ZSH_BASE_IMAGE) = "target:zsh" } : {}
```

It is `true` only on `pull_request`. On publishing events the base image is pulled from Docker Hub,
where the `zsh` job has already pushed it.

`ZSH_BASE_IMAGE` must be in *familiar* form (`ohmyzsh/zsh:5.9.2`, never
`docker.io/ohmyzsh/zsh:5.9.2`). BuildKit normalises a `FROM` reference before matching it against
named context keys, so a fully qualified key silently fails to match and the build falls through to
a registry pull — which cannot work on a pull request, because nothing has been pushed.

`bake.yml` permits exactly one target per call, plus any target reachable through a
`target:`-valued named context — which is why there is no `group "default"` in the bake file.

## Tagging

Tags come entirely from `meta-images` + `meta-tags`; `bake.yml` clears any `tags` set in the bake
file. `meta-flavor: latest=false` disables the automatic `latest` behaviour so the aliases below
are explicit.

`ohmyzsh/zsh`:

| Tag | Condition |
| --- | --- |
| `<zsh-version>` | always |
| `latest` | `zsh-version == 5.9.2` |

`ohmyzsh/ohmyzsh`:

| Tag | Condition | Job |
| --- | --- | --- |
| `<omz-version>-zsh<zsh-version>` | always | both |
| `master` | `zsh-version == 5.9.2` | `omz-latest` |
| `latest` | `zsh-version == 5.9.2` | `omz-latest` |
| `<omz-version>` | always | `omz-versions` |

Every tag is a multi-arch manifest list. Per-platform images are pushed by digest, then
github-builder's `finalize` job assembles one index per tag with `imagetools create`. On pull
requests `push` is `false`, so tags are computed and logged but nothing is published.

## What github-builder handles

- **Source**: builds from a Git context at the current commit, not a checkout. The calling workflow
  runs no `actions/checkout` for build jobs.
- **Platforms**: `distribute` defaults to true — one runner per platform, then a merge job.
- **Attestations**: SLSA provenance (`mode=max` for public repos) and SBOM.
- **Signing**: Cosign, keyless via GitHub OIDC. `sign: auto` means signing happens only when
  pushing, so pull requests never sign.
- **Cache**: GitHub Actions cache, signed and verified when OIDC is available. `zsh` and
  `omz-latest` intentionally share `cache-scope: zsh-<version>` so a linked Zsh build on a pull
  request is a cache hit rather than a recompile.

## Required secrets

| Secret | Used for |
| --- | --- |
| `DOCKERHUB_USER` | `registry-auths` for pushing, and the Docker Hub API for READMEs |
| `DOCKERHUB_TOKEN` | as above |

Absent secrets degrade gracefully: `registry-auths` is empty, the login step is skipped, and
`push` is already `false` on pull requests.

## Reproducing locally

```sh
# Print the resolved definition
docker buildx bake --print zsh
docker buildx bake --print ohmyzsh

# Build a specific Zsh version
ZSH_VERSION=5.9.2 docker buildx bake zsh

# Build Oh My Zsh against a locally built Zsh, as pull requests do
LINK_ZSH=true ZSH_VERSION=5.9.2 ZSH_BASE_IMAGE=ohmyzsh/zsh:5.9.2 \
  docker buildx bake ohmyzsh

# Lint the workflow
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest .github/workflows/main.yml
```

## Common changes

**Add a Zsh version** — add it to the `all_zsh` list in the `prepare` job. If it becomes the newest
stable release, also update `LATEST_ZSH` in that job's `env:` block. It is published on the next
push to `main`; run `workflow_dispatch` if you want it published immediately.

**Change the Debian base** — edit both `FROM` lines in `zsh/Dockerfile` together, keeping the
digest pin. Dependabot only tracks digests it can see, so dropping the `@sha256:` suffix silently
disables base-image updates: `debian:trixie-slim` carries no comparable version, so with no digest
Dependabot finds nothing to update and opens no pull requests at all.

**Add an image** — create a top-level folder with a `Dockerfile` and `README.md`, add a matching
target to `docker-bake.hcl`, and add a job calling `bake.yml` with that target.
`update-image-readme` picks up the new folder automatically.

**Bump the builder** — update both the SHA and the trailing version comment on all three
`uses: docker/github-builder/...` lines. Dependabot's `github-actions` ecosystem covers these.

## Known quirks

- The VS Code GitHub Actions extension reports three
  `Unexpected type 'BasicExpressionToken' ... 'step env'` errors. These come from line 1051 of
  Docker's `bake.yml` (one per call site), not from this repository. `actionlint` is clean and the
  real runner accepts the construct.
- `gh api` rejects `--slurp` together with `--jq`, so `prepare` slurps first and filters with a
  separate `jq`.
- **Docker Hub 429s, and which limit they come from.** Check the `docker-ratelimit-source` header:
  an IP address is the *abuse* limit (per subnet, plan-agnostic); a username (e.g. `ohmyzshbot`) is
  the *account* request quota, which does scale with Docker Hub plan tier. Both have been observed
  in production. The account quota is the one a large matrix is most likely to exhaust: `zsh`,
  `omz-latest`, and `omz-versions` push under the same account, and every version resolves several
  images (base, SBOM scanner, and for OMZ images the linked Zsh tag) before pushing. Mitigations so
  far are `max-parallel: 3` on each build matrix and running `omz-versions` strictly after
  `omz-latest` rather than alongside it — both reduce how fast the budget is spent, but since the
  quota resets hourly, they cannot guarantee staying under it if a full rebuild's total request
  count exceeds the quota within that hour. Raising the Docker Hub plan tier for the pushing account
  removes the account-quota ceiling outright; check `docker-ratelimit-source` on the next failure
  before assuming which limit is in play.
- Named context keys must use the familiar image form. `docker.io/ohmyzsh/zsh:5.9.2` as a key does
  not match `FROM docker.io/ohmyzsh/zsh:5.9.2`; `ohmyzsh/zsh:5.9.2` does. This failure is silent —
  the build just pulls from the registry instead.
- `harden-runner` cannot be applied to the build jobs, because a caller cannot inject steps into a
  reusable workflow. It runs only in `prepare` and `update-image-readme`.

[github-builder]: https://github.com/docker/github-builder
[abuse-limit]: https://docs.docker.com/docker-hub/usage/#abuse-rate-limit
