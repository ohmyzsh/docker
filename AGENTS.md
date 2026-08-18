# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this repository is

Dockerfile sources for the images published at
[hub.docker.com/u/ohmyzsh](https://hub.docker.com/u/ohmyzsh). It ships no application code — the
deliverables are container images and the CI that produces them.

Two images:

- **`ohmyzsh/zsh`** — Zsh compiled from source out of `zsh-users/zsh`, on `debian:trixie-slim`.
  Covers 38 versions from `master` down to 4.3.10.
- **`ohmyzsh/ohmyzsh`** — Oh My Zsh installed on top of a pinned `ohmyzsh/zsh` image.

## Layout

| Path | Purpose |
| --- | --- |
| `zsh/Dockerfile` | Multi-stage source build; applies `zsh/patches/*.patch` |
| `ohmyzsh/Dockerfile` | `FROM ${ZSH_BASE_IMAGE}`, runs the OMZ installer |
| `docker-bake.hcl` | Bake targets `zsh` and `ohmyzsh` |
| `.github/workflows/main.yml` | The only workflow; calls `docker/github-builder` |
| `.github/scripts/update-image-readme.js` | Pushes READMEs to Docker Hub |
| `docs/ci-workflow.md` | **Read this before touching CI** |
| `<image>/README.md` | Published verbatim as the Docker Hub description |

## Commands

```sh
docker buildx bake --print zsh                  # resolve a target
ZSH_VERSION=5.9.2 docker buildx bake zsh        # build one version
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest .github/workflows/main.yml
```

There is no test suite, package manager, or build script. Validation is `bake --print`,
`actionlint`, and a real CI run.

## Invariants

Breaking any of these breaks CI in ways local linting will not catch.

1. **Reusable-workflow `with:` inputs cannot read the `env` context.** Shared constants live as
   `prepare` job outputs. Never reintroduce a workflow-level `env:` block for values consumed by
   `with:`.
2. **`bake.yml` allows exactly one target per call**, plus targets reachable via a `target:`-valued
   named context. Do not add a `group` containing both targets.
3. **Tags come only from `meta-images` / `meta-tags`.** `bake.yml` clears `tags` in the bake file,
   so setting them there has no effect.
4. **Build jobs get a Git context, not a checkout.** Do not add `actions/checkout` to them; paths
   in `docker-bake.hcl` are relative to the repository root.
5. **Image folders are discovered by globbing `*/Dockerfile`.** A new image folder needs a
   `README.md` or `update-image-readme` emits a warning.
6. **Keep actions SHA-pinned** with a trailing version comment, including the reusable workflow.

## Decisions and accepted tradeoffs

**Delegating builds to `docker/github-builder`.** Gains signed SLSA provenance, SBOMs, signed
cache, and per-platform distribution without maintaining that logic here. Costs: build logic is no
longer inspectable in-repo, `harden-runner` cannot cover build jobs (a caller cannot inject steps
into a reusable workflow), and upgrades are gated on Docker's release cadence. Accepted — the
supply-chain properties are worth more than local control.

**Hybrid base-image resolution (`LINK_ZSH`).** Pull requests link `ohmyzsh` to the `zsh` bake
target so they validate against their own Zsh build; publishing events pull the already-pushed
image from Docker Hub. The alternative — always linking — would rebuild Zsh twice per version.
Verified: buildx keeps `output: cacheonly` on a linked dependency target even under
github-builder's `*.output` wildcard override, so the linked Zsh is never published under the
`ohmyzsh` name.

**Full matrix only on schedule and dispatch.** 38 versions × ~5 jobs × two matrices is a large
run. Pushes to `main` build only the latest Zsh; pull requests build three versions
(`master`, latest, and `4.3.11`, which exercises the patch and static PCRE backport paths).
Tradeoff: historical tags are refreshed weekly rather than per merge, so a regression affecting
only old versions can sit undetected for up to a week.

**Docker Hub PAT rather than OIDC.** `registry-identities` with `type: dockerhub` would remove the
long-lived token, but requires an OIDC connection configured in the Docker Hub organisation.
Deferred, not rejected.

**Zsh version list inline in the workflow.** A `prepare` job is required regardless, so a separate
data file would add a moving part without removing one. Tradeoff: version bumps touch CI YAML.

**Single `docker.io/...` image name.** The previous workflow pushed both `ohmyzsh/zsh:x` and
`docker.io/ohmyzsh/zsh:x` — the same registry twice. Collapsed to one; no user-visible change.

**Tag format `<omz-version>-zsh<zsh-version>`.** Changed from the older `<zsh>-<omz>` ordering.
Note this is a **breaking rename**: previously published tags in the old format remain on Docker
Hub and are never refreshed again, so anyone pinned to them silently receives a frozen image
rather than an error.

## Known quirks

- **`omz-versions` never runs.** `ohmyzsh/ohmyzsh` has no git tags, so its matrix is `[]` and the
  job always skips. The tagging scheme is currently dead code, kept for when tags reappear.
- **Three phantom editor errors.** The VS Code GitHub Actions extension flags
  `Unexpected type 'BasicExpressionToken' ... 'step env'` three times. The source is line 1051 of
  Docker's `bake.yml`, once per call site — not this repository. `actionlint` is clean.
- **`gh api` rejects `--slurp` with `--jq`.** `prepare` slurps, then filters with a separate `jq`.
- **Forks are blocked** by `if: github.repository == 'ohmyzsh/docker'` on `prepare`. Comment it out
  to test in a fork.

## Conventions

- Comments explain *why*, not *what*, and stay to one line where possible.
- Shell in workflows uses `set -euo pipefail` and passes untrusted values through `env:` rather
  than interpolating `${{ }}` directly into scripts.
- Dockerfiles use `SHELL ["/bin/sh", "-euxc"]` and `apt-get` cleanup in the same layer.
