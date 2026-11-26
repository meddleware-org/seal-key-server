# CLAUDE.md — seal-key-server

A **contingency** container image of the upstream [MystenLabs/seal](https://github.com/MystenLabs/seal) key server: the `key-server` and `seal-cli` binaries built from a pinned release
and published, signed and attested by a tag-triggered workflow. It is **not deployed**: Sealed Storage uses independent key-server operators (workspace ADR-0002), and this image exists so a
self-hosted, custodial server can be stood up quickly if they become unavailable. The repository holds no first-party application code, only the build, the pipelines and the licence notices.

## Layout

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Clones the pinned upstream tag, checks its commit, builds `key-server` and `seal-cli` with `cargo auditable`, generates the licence notices, assembles a distroless non-root image |
| `VERSION` | The image version; a `v*` tag must equal it |
| `about.toml`, `about.hbs` | `cargo about` configuration and template: the accepted licences and the layout of the third-party notices |
| `scripts/smoke.sh` | Smoke test of a built image (user, tools, refusal without configuration, licence files) |
| `.github/workflows/ci.yml` | hadolint, actionlint, Trivy configuration scan, an amd64 build, an image scan and the smoke test; reused by the release |
| `.github/workflows/docker-publish.yml` | Release on a `v*` tag: native per-architecture builds without registry credentials, push, merge, scan, sign, attest |
| `.github/workflows/rescan.yml` | Weekly rescan of the newest published image and a watch for a newer upstream release |
| `.github/dependabot.yml` | Weekly grouped updates of the base-image digests (not the Rust image) and the Actions |
| `docs/audit/seal-key-server-audit.md` | The audit |

## Commands

```bash
hadolint Dockerfile
docker build --target notices .                                # the licence notices alone; fails on an unaccepted licence
docker build --build-arg VERSION=dev -t seal-key-server:dev .  # a long Rust compile
bash scripts/smoke.sh seal-key-server:dev
```

Release: bump `VERSION`, push a `v<version>` tag, and the `Publish (Docker)` workflow does the rest. Deploy by the signed index digest, never by tag.

## Conventions and hard rules

- **Pin by tag and commit.** `SEAL_TAG` and `SEAL_COMMIT` move together; the build fails if the commit differs, so the source cannot move under the tag (audit F10).
- **The Rust image version equals the release's `rust-toolchain.toml`**, so rustup downloads nothing. Dependabot ignores that image; it moves with `SEAL_TAG`.
- **Builds hold no registry credentials.** Each architecture exports an OCI archive; only the short push job logs in (audit F3).
- **Exact version tags only** (no `latest`, no `0.0`): a floating tag gives a deployer nothing the digest does not (audit F5).
- **Every linked crate's licence must be accepted by `about.toml`.** `cargo about generate --fail` stops the build otherwise; add a licence there deliberately, never to silence a failure.
- **Never deployed without the maintainer's decision.** A self-hosted server is custodial (its operator could decrypt what it serves); the UI then shows that notice.
- Workspace rules (0BSD, patch-only versions until mainnet, one short commit message, no push without approval) apply: see the workspace `CLAUDE.md`.

## Gotchas

- The build compiles hundreds of crates; CI uses the GitHub layer cache, a local build takes a long time.
- Build-stage `apt` packages float on purpose (hadolint DL3008 is ignored with a reason); they never reach the runtime image.
- The crate advisory scan is report-only (audit F13, OQ5): the pinned upstream release carries advisories this repository cannot fix.
- The weekly rescan has no `latest` tag to read: it picks the highest `X.Y.Z` tag, and the `<commit>-<arch>` build intermediates never match.

## Related

The audit `docs/audit/seal-key-server-audit.md`, workspace ADR-0002 (the key-server choice) and ADR-0003 (the naming), the deployment kit in the workspace `post-bootstrap/_contingency/seal-key-server/`, and `SECURITY.md` for the `cosign verify` command.
