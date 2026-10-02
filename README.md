# seal-key-server

Contingency container image of the upstream [MystenLabs/seal](https://github.com/MystenLabs/seal)
key server. It is **not deployed**: Sealed Storage uses key servers run by independent operators
(workspace `docs/architecture/ADR-0002-seal-key-servers.md`). This image exists so a self-hosted
server can be stood up quickly if those servers become unavailable. A self-hosted server is
custodial (its operator could decrypt what it serves), so seal-ui then shows that notice.

## What is in the image

| Path | Purpose |
| --- | --- |
| `/usr/local/bin/key-server` | The Seal key server (entrypoint). Port 2024 (API), 9184 (metrics). |
| `/usr/local/bin/seal-cli` | Master-seed and key tooling, e.g. `--entrypoint /usr/local/bin/seal-cli … gen-seed`. |

- **Source:** upstream release `seal-v0.6.15`, commit `d0ab560e8dfffe31397728fe284936085a7a7100`. The
  Dockerfile clones the tag and refuses to build if the commit differs.
- **Build:** Rust 1.96.1 (the release's `rust-toolchain.toml`), `cargo build --locked --release`.
- **Runtime:** `gcr.io/distroless/cc-debian12:nonroot`, user 65532, no shell. Base images are pinned
  by digest.
- **Licence:** the image contains Apache-2.0 software from MystenLabs/seal; this repository's own
  files are 0BSD.

## Releases

Push a `v*` tag equal to `VERSION`. The `Publish (Docker)` workflow builds amd64 and arm64 on native
runners, merges them into one manifest on `quay.io/meddleware-org/seal-key-server` and
`docker.io/meddleware/seal-key-server`, signs it with keyless cosign, and attaches an SPDX SBOM and
build provenance.

Repository configuration: secrets `QUAY_USERNAME`, `QUAY_TOKEN`, `DOCKERHUB_USERNAME`,
`DOCKERHUB_TOKEN`; variables `QUAY_NAMESPACE`, `DOCKERHUB_NAMESPACE` (defaults `meddleware-org`,
`meddleware`).

To follow a new upstream release: update `SEAL_TAG` and `SEAL_COMMIT` in the Dockerfile (and the Rust
image if the release's `rust-toolchain.toml` changed), bump `VERSION`, tag.

## Using it

The deployment kit and runbook live in the infrastructure workspace:
`post-bootstrap/_contingency/seal-key-server/` (Permissioned mode, allowlisting only MeddleWare's
`seal_policies` package; the master seed is generated on the cluster node and stored with SOPS).
