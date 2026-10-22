# Security policy

This repository builds a **contingency** container image of the upstream
[MystenLabs/seal](https://github.com/MystenLabs/seal) key server. It contains no first-party application
code. The image is not deployed: Sealed Storage uses independent key-server operators (workspace
ADR-0002), and this image exists so a self-hosted server can be stood up if they become unavailable.

## What to report here

In scope:

- the image build and publish pipeline (Dockerfile, workflows, signing, attestations, tags);
- the image contents we control: the pinned source and base-image digests, the user, the licence notices.

Out of scope:

- vulnerabilities in the Seal key server itself: report them to MystenLabs
  (<https://github.com/MystenLabs/seal/security>);
- the deployment kit, master-seed custody and on-chain registration, which live in the infrastructure
  workspace (`post-bootstrap/_contingency/seal-key-server/`).

Report privately to <security@meddleware.co.uk>; do not open a public issue. You will get an
acknowledgement within 3 business days.

## A self-hosted key server is custodial

Whoever runs a key server holds the master seed and could decrypt anything it serves keys for. Running
this image makes MeddleWare that custodian, so Sealed Storage then shows that notice (seal-ui). Generate
the master seed offline (a local `docker run --rm` with no log shipping, or an air-gapped machine) and
store it directly in SOPS; never generate or print it in the cluster, where container output is
collected.

## Verifying an image

Deploy by the **index digest** of a signed release, never by tag. The per-architecture tags
(`<commit>-amd64`, `<commit>-arm64`) are build intermediates. Releases carry exact version tags only; the
`latest` and `<major>.<minor>` tags of releases up to 0.0.2 are frozen and must not be used.

```bash
cosign verify \
  --certificate-identity-regexp '^https://github.com/meddleware-org/seal-key-server/\.github/workflows/docker-publish\.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  quay.io/meddleware-org/seal-key-server@sha256:<index digest>
```

The same signature, an SPDX SBOM attestation and a build-provenance attestation are attached on
`docker.io/meddleware/seal-key-server`.

## Supported versions

Only the latest published release receives fixes. A weekly workflow rescans the newest published release image and opens an
issue when upstream publishes a newer Seal release.

Known advisories in the compiled Rust dependencies of the pinned upstream release (the crate list is embedded in the binaries and scanned by
Trivy) are **reported, not gated**, while this contingency image is not deployed. Before the kit is activated or the next upstream Seal release is
adopted, each advisory gets a documented reachability review and either a fix by upgrading or an expiring allowlist entry; the procedure is under
OQ5 in `docs/audit/seal-key-server-audit.md`.
