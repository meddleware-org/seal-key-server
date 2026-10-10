# Security Audit — `seal-key-server`

**Classification:** Internal security review (initial audit 2026-10-03, re-verified 2026-10-09 —
awaiting external review)
**Project:** seal-key-server — a **contingency** container image of the upstream
[MystenLabs/seal](https://github.com/MystenLabs/seal) key server.

- It contains the `key-server` and `seal-cli` binaries.
- It is built from a pinned upstream release and published, signed and attested by a tag-triggered
  workflow.
- It is **not deployed**. Sealed Storage uses independent key-server operators (workspace ADR-0002).
  The image exists so a self-hosted, custodial server can be stood up quickly if those operators
  become unavailable.

**Project type:** Container image build (Dockerfile + GitHub Actions CI and publish workflows); no
first-party application code. The upstream Rust workspace is compiled, not reviewed.

**Template:**

- AUDIT_TEMPLATE.md (2026-10-08)
- AUDIT_TEMPLATE_IMG.md (2026-10-08)
- AUDIT_TEMPLATE_SEAL.md (2026-09-30), applied to the key-server side: the trust matrix and committee
  readiness. The SDK/client rows are N/A.
- AUDIT_TEMPLATE_RUST.md (2026-10-08), scoped to the **build** of upstream Rust: B.1 advisories and
  bans, B.RS-1 build, toolchain and lockfile (F13). Section A rows (memory safety, panics, HTTP
  hygiene, …) concern upstream code and are N/A.
- AUDIT_TEMPLATE_AUTH.md (2026-10-08), scoped to **key material**: the image holds none, but the
  master seed and the registry credentials are held by the kit and the workflows (B.AUTH-1, F3, F8).
  The token, IdP and client rows are N/A.

Not triggered:

| Lens | Why not |
| --- | --- |
| OPS | Nothing in this repository signs on a chain. Registering the on-chain `KeyServer` object is a manual step of the kit's runbook (F8). |
| PLATFORM | The cluster, node and secret store belong to the platform audit; the kit's cluster-side items are recorded in F8. |
| TS, VUE, WALRUS, SUI_CLIENT, WORKERS, GO, SITE, PROXY | No matching code. |

**Deployment status:** contingency, not deployed; mainnet key servers are Overclock/NodeInfra/H2O Open
mode 2-of-3 (D24). Image `0.0.2` is published and cosign-signed, and pinned in `config/images.yaml`
as a contingency entry (index `sha256:8609cbbe…5497134`). The kit is not discovered by `apply.sh`.

**Images:**

- `quay.io/meddleware-org/seal-key-server:0.0.2` and `docker.io/meddleware/seal-key-server:0.0.2` @ the
  same index `sha256:8609cbbe4adb171f84f95170102061340d8ff02e639fc44faf8f8c71f5497134`, published
  2026-10-08 (tag `v0.0.2`, run 37782631292).
  - amd64 `sha256:2bf5cbe1cab1…`; arm64 `sha256:69123ca77a91…`.
  - Also tagged `0.0` and `latest` on both registries.
  - Intermediate tags `b0c8751…-amd64` / `-arm64` (F5).
  - Both registries were inspected on 2026-10-09 and serve the same index.
- Superseded: `0.0.1` @ index `sha256:e884712d7ce54e2396bbb2143aeb0f238abc2783fdf710c43366badaa06f7465`
  (2026-10-02, amd64 `84cd7fbb1caa…`, arm64 `01f3e9bfc80f…`; tags `0.0.1` and intermediates
  `bea51d96…-amd64` / `-arm64` remain). Built before the F1/F2/F3/F7/F9 fixes; the kit rehearsal of
  2026-10-02 used it.

**Base images:**

| Stage | Image |
| --- | --- |
| Build | `docker.io/library/rust:1.96.1-slim-bookworm@sha256:e18a79fc84dfcfc3ab5ba72290398a644c135c97eaa881447fddc354ee4701a3` |
| Runtime | `gcr.io/distroless/cc-debian12:nonroot@sha256:9dac0a79194e45a7da0158a9c6da57b217585af0786db3845d1f0ec1a0dd182f` |

**Runtime user:** `65532:65532` (distroless nonroot; confirmed in the published image config
2026-10-09); no shell, no package manager.
**Runtime FS:** read-only root filesystem, set by the deployment kit (reviewed 2026-10-09 — F8).

**Deployed by:** not deployed (contingency). The kit is `post-bootstrap/_contingency/seal-key-server/`
in the infrastructure workspace (read-only review 2026-10-09 — F8). Its overlay pins the image by digest
from `config/images.yaml` (`0.0.2` @ `sha256:8609cbbe…`); `kubectl kustomize` renders
`quay.io/meddleware-org/seal-key-server@sha256:8609cbbe…`.

**Build args (none secret):**

| Arg | Purpose |
| --- | --- |
| `SEAL_TAG` = `seal-v0.6.15` | upstream release tag |
| `SEAL_COMMIT` = `d0ab560e8dfffe31397728fe284936085a7a7100` | commit the tag must resolve to |
| `VERSION` (the git ref name, `v0.0.2`) | image label (F15) |

**SEAL lens front matter:**

| Item | Value |
| --- | --- |
| Seal SDK | n/a (server). Upstream `key-server` at `seal-v0.6.15`, still the latest upstream release on 2026-10-09 (`git ls-remote` and `releases/latest`). |
| Key-server mode | Permissioned (per the README and kit), allowlisting only Meddleware's `seal_policies` package |
| Key servers per network | none deployed. Mainnet uses Overclock, NodeInfra and H2O Nodes in Open mode, threshold 2 (ADR-0002, D24). |
| Threshold | set by consumers (seal-ui). A lone self-hosted server means a t = 1 custodial committee; the kit's runbook step 7 keeps t = 2 while an independent server remains (F8, OQ2). |
| Policy package to allowlist | the kit targets **mainnet**: the `seal_policies` original id, filled at activation (not yet published on mainnet). Testnet, for rehearsal: `0x0c8f73490b14836e6a7a724fb46b242cb061d04a5f193fd637159997f8a1773d` (republished 2026-10-09; the earlier `0x61c4aa…` is superseded and immutable — see `seal-policies-sui-audit.md`). |

**Review date:** 2026-10-03; re-verified 2026-10-09
**Reviewer:** Internal review
**Severity ceiling:** High.

- A key server holds a master secret that derives decryption keys for every identity it approves.
- A tampered image, or a leaked seed, compromises the confidentiality of everything sealed to that
  server.
- Realised ceiling at this pass: **Low**. The image is not deployed, and its build and supply chain
  are strong. The deployment-time risks are recorded as pre-deploy gates (F8).

**Status:** re-verified 2026-10-09 at HEAD `4eb832b` (Dependabot Actions bump after tag `v0.0.2` =
`b0c8751`; `VERSION` = `0.0.2`). The first pass (2026-10-03) was at `bea51d9` = `v0.0.1`.

**Location:** `seal-key-server/docs/audit/seal-key-server-audit.md`. This is a new directory in the
repo; the file is not yet committed there.

> **Access note:** `meddleware-org/seal-key-server` is public and was cloned read-only. Nothing was
> pushed. The 2026-10-09 pass also read the kit in the infrastructure workspace and the published
> images on quay.io and Docker Hub.

---

## Executive summary

The repository packages someone else's server, and does so carefully. At the first pass (2026-10-03)
it was five files; at `v0.0.2` it adds `ci.yml`, `rescan.yml`, `dependabot.yml`, `SECURITY.md`,
`about.toml` / `about.hbs` (licence notices) and `scripts/smoke.sh`. Between the first pass and
2026-10-09 every finding that could be fixed in the repository was fixed and released as `0.0.2`
(commit `71df539`, plus follow-ups to `b0c8751`).

**Build:**

- **Pinned source, verified at build.** The upstream source is pinned by tag **and** commit, and the
  build refuses to proceed if the tag has moved.
  - Re-verified 2026-10-09: `git ls-remote` shows `refs/tags/seal-v0.6.15` = `d0ab560e…`, and
    `seal-v0.6.15` is still the latest upstream release.
- **Matched toolchain.** The build image's Rust 1.96.1 equals the upstream `rust-toolchain.toml`
  (verified 2026-10-03; the Dockerfile and upstream tag are unchanged).
- **Locked build.** `cargo build --locked` builds only `key-server` and `seal-cli`, and only those two
  binaries (plus licence texts) reach the runtime stage.
- **Licence notices (F1).** A `notices` stage runs a pinned `cargo about generate --fail`, so a
  dependency under an unaccepted licence fails the build. Both binaries' third-party notices and the
  upstream `LICENSE` are in `/usr/share/doc/seal-key-server/` (checked in the published image).

**Runtime:** distroless, non-root, no shell, both bases digest-pinned. This is markedly harder than
upstream's own Dockerfile, which uses unpinned `debian:bullseye-slim`, runs as root, `apt`-installs
PostgreSQL and uses a bash entrypoint.

**Publish chain:**

- SHA-pinned actions; least-privilege permissions per job.
- **Release gate = CI (F2).** The tag workflow calls `ci.yml` (hadolint, actionlint, Trivy config, an
  amd64 build, a Trivy image scan and `scripts/smoke.sh`) on the tagged commit, then scans the
  published image before cosign signs it. A weekly workflow rescans the latest image.
- **Credential-less builds (F3).** The architecture builds run without registry credentials and
  export OCI archives; a short job logs in only to push them.
- Native amd64 and arm64 builds; keyless cosign signing **at the index digest**.
- **Verified on both registries (2026-10-09).** The OCI referrers API on quay.io and Docker Hub shows
  three Sigstore bundles on index `sha256:8609cbbe…5497134`, each with a Fulcio certificate and a
  Rekor entry; the certificate identity of all six is
  `…/seal-key-server/.github/workflows/docker-publish.yml@refs/tags/v0.0.2` (issuer
  `token.actions.githubusercontent.com`):
  - a cosign signature;
  - an SPDX SBOM attestation (`https://spdx.dev/Document`);
  - SLSA v1 build provenance.
  - The cosign signature was also verified by `bootstrap/images/verify-digests.sh` on 2026-10-09
    (16/16 images valid, this one included).

**Dispositions (F1–F16):**

| ID | Severity | Finding | Disposition |
| --- | --- | --- | --- |
| F1 | Low | Licence texts not shipped | RESOLVED (0.0.2) |
| F2 | Low | No build, scan or smoke test before a release tag | RESOLVED (0.0.2; F16 for the arm64 residual) |
| F3 | Low | Static registry tokens in the jobs that compile third-party code | MITIGATED (builds credential-less; the inventory is `OPERATOR_TASKS.md`) |
| F4 | Info | Unpinned apt packages in the build stage | ACCEPTED-RISK (reason recorded in the Dockerfile) |
| F5 | Info | Mutable and intermediate tags | MITIGATED (digest-only deployment documented and enforced by the overlay) |
| F6 | Info | `seal-cli` in the server image | ADJUDICATED (runbook requirement now in SECURITY.md and the kit) |
| F7 | Info | No upstream-release or base-image watch | RESOLVED (0.0.2) |
| F8 | Info here, **blocking before any deployment** | Deployment kit, seed custody, custodial posture | DEFERRED (contingency-activation gate; the kit was reviewed read-only and mostly holds) |
| F9 | Info | No `SECURITY.md` | RESOLVED (0.0.2) |
| F10–F12 | Positive | Pinned source, runtime, publish chain | re-verified for 0.0.2 |
| F13 | Low | The SBOM and the image scan do not see the compiled crate graph | DEFERRED (pre-mainnet scan gate) |
| F14 | Positive | CI-equals-release gate, credential-less builds, fail-closed licences | new |
| F15 | Info | The image `version` label carries `v0.0.2` | ACCEPTED-RISK |
| F16 | Info | arm64 is not scanned or smoke-tested before release | ACCEPTED-RISK |

Counts (16 findings): 4 RESOLVED (F1, F2, F7, F9); 2 MITIGATED (F3, F5); 1 ADJUDICATED (F6);
3 ACCEPTED-RISK (F4, F15, F16); 2 DEFERRED (F8, F13); 4 Positive (F10–F12, F14).

The first pass recorded findings only, by maintainer instruction; the base template's resolve-inline
rule was applied in the code work between 2026-10-03 and 2026-10-09 (see the re-verification log).

---

## Threat model / trust boundaries

### Image supply-chain matrix (IMG lens, mandatory)

| Actor / asset | Power | Bounded by |
| --- | --- | --- |
| Upstream MystenLabs/seal maintainers / GitHub | The source that is built | Tag **and** commit pinned and checked in the build (`Dockerfile:24-25`); a moved tag fails the build; weekly upstream-release watch (F7) |
| crates.io / upstream `Cargo.lock` | Every Rust dependency compiled in | `cargo build --locked` (lockfile checksums); accepted-licence list with `--fail` (`about.toml`, F1); upstream `deny.toml` exists but is not run here, and the crate graph is not in the SBOM or the image scan (F13) |
| Base-image publishers (Docker library rust, Google distroless) | Build toolchain; runtime glibc and CA store | Digest pinning on both `FROM` lines; Dependabot digest bumps (distroless only — F7); Trivy image scan (F2) |
| Debian mirrors (build stage) | `git`, `clang`, `cmake`, `libssl-dev`, … | Unpinned versions, accepted with a recorded reason (F4); build stage only, not copied to runtime |
| Build context | Files sent to the builder | Context is the Dockerfile, `about.toml`, `about.hbs` and `LICENSE` (`.dockerignore` drops `.git`, `.github`, `*.md`); the only `COPY`s from the context are those files |
| CI and publish jobs | What is built, pushed and signed | SHA-pinned actions, scoped permissions, tag gate, release = CI (F14); the builds hold no registry credentials; the push and merge jobs do (F3) |
| Registries (quay.io, Docker Hub) | Manifest served per tag | Signatures and attestations at the index digest; mutable `latest` / `0.0` and unsigned intermediate tags (F5) |
| Cluster operator / kit manifests | How the container runs and what the seed is exposed to | Kit pod security, network policy and digest overlay (F8) |
| Anyone who pulls the image | All layers | No secrets in any layer or arg; distroless runtime |

### Seal trust matrix — key-server side (SEAL lens)

| Party | Power | Consequence / bound |
| --- | --- | --- |
| **Operator of this server (Meddleware, if deployed)** | Holds the master seed; derives keys for every approved identity | Can decrypt everything sealed to this server. As the only server (t = 1) the system is **fully custodial**; with t ≥ 2 plus independent operators, it is one share. seal-ui marks this with `VITE_SEAL_KEY_CUSTODY_{NET}=operator` (F8, OQ2). |
| Anyone with the `MASTER_KEY` env value / SOPS Secret | The same as the operator | Seed custody is the kit's (F8, B.AUTH-1) |
| Allowlisted policy package (Permissioned mode) | Which identities can ever be served | Must be the policy's **first-published (original) id**. Each `seal_policies` republish creates a new namespace that must be added; dropping an old one strands its content (F8). |
| The full node the server dry-runs against | The chain view used for `seal_approve*` | Stale or divergent state; clock skew for `timelock` (`seal-policies-sui-audit.md` F26) |
| Metrics endpoint (9184) | Operational data | Not routed by the kit's ingress (`/v1/` prefix only); network policy admits only the `monitoring` namespace (F8) |
| Image supply chain | The server's code | Matrix above |

---

## Severity scale

Critical / High / Medium / Low / Info / Positive.

## Scope

**In scope (HEAD `4eb832b`, 2026-10-09; release tag `v0.0.2` = `b0c8751`, 2026-10-08):** `Dockerfile`,
`.dockerignore`, `.github/workflows/{ci,docker-publish,rescan}.yml`, `.github/dependabot.yml`,
`scripts/smoke.sh`, `about.toml`, `about.hbs`, `README.md`, `SECURITY.md`, `VERSION`, `LICENSE`. The
only change after the tag is the Dependabot Actions bump (`4eb832b`; the two workflows differ by six
lines of action pins from the tagged ones). The first pass covered `bea51d9` = `v0.0.1`.

**Cross-checked (read-only):**

- upstream `MystenLabs/seal` at `seal-v0.6.15`: tag → commit, `rust-toolchain.toml`, `LICENSE`, the
  upstream `Dockerfile`, and the `key-server` configuration surface (`MASTER_KEY`, `CONFIG_PATH`,
  `NODE_URL`, `NETWORK`, `PORT` in `crates/key-server/src/{master_keys,server}.rs`);
- quay.io and Docker Hub tags, OCI referrers, image config and layers of the published image;
- the deployment kit `post-bootstrap/_contingency/seal-key-server/` (all files) and the
  `config/images.yaml` entry (F8);
- workspace ADR-0002 and `OPERATOR_TASKS.md` ("Mainnet Seal key servers", "Image registry
  credentials");
- `seal-ui/src/config.ts` and seal-ui `CLAUDE.md` (custody notice, defaults);
- `seal-policies-sui` (the package to allowlist).

**Out of scope:**

- the upstream Rust code;
- the cluster, its node, secret store (SOPS age key) and RBAC, which belong to the platform audit;
- the independent key-server operators.

**Environment / commands (2026-10-03, first pass):**

| Command | Result |
| --- | --- |
| `git ls-remote https://github.com/MystenLabs/seal refs/tags/seal-v0.6.15` | `d0ab560e8dfffe31397728fe284936085a7a7100` (lightweight tag; matches `SEAL_COMMIT`) |
| `git ls-remote --tags …/seal \| sort -V` | latest `seal-v*` = `seal-v0.6.15` |
| Shallow clone at the tag | `rust-toolchain.toml` channel `1.96.1` (matches); `LICENSE` (Apache-2.0) present; no `NOTICE` |
| Docker Hub tags API | `0.0.1`, `0.0`, `latest` → index `sha256:e884712d…7465` (amd64 `84cd7fbb…`, arm64 `01f3e9bf…`); intermediates `bea51d96…-amd64` / `-arm64` |
| Registry OCI referrers on the index digest | 3 Sigstore v0.3 bundles. Decoded statements: `https://sigstore.dev/cosign/sign/v1`, `https://spdx.dev/Document`, `https://slsa.dev/provenance/v1`. Each subject = the index digest; each has a certificate, tlog entries and timestamp data. (The SBOM referrer's annotation says `sign/v1`; the statement inside is SPDX.) |
| Signing-certificate identity (SAN) | not verified in the first pass (Docker Hub anonymous pull rate limit); done 2026-10-09, below |
| Building the image locally | not run: no Docker daemon in the first-pass sandbox |
| quay.io | not reachable in the first pass (egress policy); inspected 2026-10-09, below |

**Environment / commands (2026-10-09, re-verification):**

| Command | Result |
| --- | --- |
| `git -C repos/seal-key-server log`, `git diff --stat v0.0.2 HEAD`, `gh run list` | Tag `v0.0.2` = `b0c8751`; `VERSION` 0.0.2; HEAD `4eb832b` differs from the tag by two workflow files (action pins). `Publish (Docker)` run on `v0.0.2` succeeded (14m42s); `CI` on `main` green on 2026-10-09 (run 37962113785) |
| `git ls-remote …/seal 'refs/tags/seal-v0.6.*'`, `gh api repos/MystenLabs/seal/releases/latest` | `seal-v0.6.15` = `d0ab560e…` and is the latest release |
| `skopeo inspect --raw` / `list-tags` on both registries | `0.0.2` → index `sha256:8609cbbe…5497134` on quay.io and Docker Hub (amd64 `2bf5cbe1…`, arm64 `69123ca7…`, two attestation manifests); tags `0.0`, `0.0.1`, `0.0.2`, `latest`, intermediates for `b0c8751…` and `bea51d9…`; matches `config/images.yaml` and the overlay |
| `skopeo inspect --config` (amd64) | `User` `65532:65532`; entrypoint `/usr/local/bin/key-server`; labels `io.meddleware.seal.{tag,commit}` correct; `org.opencontainers.image.version` = `v0.0.2` (F15) |
| Registry OCI referrers on the index digest (both registries), decoded | 3 bundles each: cosign `sign/v1`, SPDX, SLSA v1. Every certificate SAN = `https://github.com/meddleware-org/seal-key-server/.github/workflows/docker-publish.yml@refs/tags/v0.0.2`, issuer `https://token.actions.githubusercontent.com`; each has one Rekor entry; each subject = the index digest. The cosign signature was not re-verified cryptographically by this pass (no `cosign` binary); `verify-digests.sh` (cosign) passed 16/16 on 2026-10-09 |
| Decoded SPDX SBOM | 12 packages, all distroless OS packages (`base-files`, `libc6`, `libssl3`, …) plus the image itself; no Rust crate (F13) |
| Layer listing of the amd64 image | `/usr/local/bin/{key-server,seal-cli}` and `/usr/share/doc/seal-key-server/{LICENSE-seal,LICENSE-seal-key-server,THIRD_PARTY_LICENSES-key-server.txt,THIRD_PARTY_LICENSES-seal-cli.txt}` (609 KB / 518 KB; 300 Apache-2.0, 91 MIT, … crates listed); `key-server` has no `cargo-auditable` section (F13) |
| `kubectl kustomize post-bootstrap/_contingency/seal-key-server/overlays/default` | Renders `image: quay.io/meddleware-org/seal-key-server@sha256:8609cbbe…` (F8) |
| Building or running the image locally | not run (no local build; the CI smoke test is the evidence, F2) |

**Operator verification (one command per registry):**

```bash
cosign verify quay.io/meddleware-org/seal-key-server@sha256:8609cbbe4adb171f84f95170102061340d8ff02e639fc44faf8f8c71f5497134 \
  --certificate-identity-regexp '^https://github.com/meddleware-org/seal-key-server/\.github/workflows/docker-publish\.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
gh attestation verify oci://quay.io/meddleware-org/seal-key-server@sha256:8609cbbe… -R meddleware-org/seal-key-server
```

Repeat both for `docker.io/meddleware/seal-key-server`. `SECURITY.md` carries the `cosign verify`
command with the anchored workflow identity.

---

## Findings

### F1 — The image redistributes Apache-2.0 and third-party binaries without licence texts

**Severity:** Low   **Disposition:** RESOLVED (0.0.2, commit `71df539`)
**Where:** `Dockerfile:27-43` (the runtime stage copies only the two binaries); `README.md:21-22`.
(At `v0.0.2` the same concern is `Dockerfile:27-37, :57-60`.)

**Issue:**

- The published image contains `key-server` and `seal-cli`, built from Apache-2.0 MystenLabs/seal.
  It also contains several hundred statically linked crates under various licences (MIT, Apache-2.0,
  BSD, …).
- Apache-2.0 §4(a) requires giving recipients a copy of the licence with redistributed binaries, and
  many MIT/BSD crates require their notice to be reproduced.
- The image carries only an `org.opencontainers.image.licenses` label. The SPDX SBOM lists components
  but does not reproduce licence texts.

**Impact:** licence non-compliance for a publicly distributed image on two registries. No security
impact.

**Remediation / evidence:** fixed in `0.0.2`, as recommended in the first pass.

- A `notices` build stage (`Dockerfile:27-39`) installs a pinned `cargo-about` 0.9.2 (`--locked
  --version`) and runs `cargo about generate --locked --fail` per binary against `about.toml` (an
  explicit accepted-licence list) and `about.hbs`. A dependency under any other licence fails the
  build. `mvr-types` has no licence field upstream, so `about.toml` clarifies it as Apache-2.0 against
  a checksum of the repository `LICENSE` (commits `563856a`, `9af9b45`); the clarification stops
  applying if that text changes.
- The runtime stage copies the output and this repository's `LICENSE` into
  `/usr/share/doc/seal-key-server/` (`LICENSE-seal`, `LICENSE-seal-key-server`,
  `THIRD_PARTY_LICENSES-key-server.txt`, `THIRD_PARTY_LICENSES-seal-cli.txt`). The README ("What is in the image" → Licence) documents them.
- `scripts/smoke.sh` fails when any of the four files is missing or empty; the CI image build runs the
  `notices` stage as part of the full build (`b0c8751`), so a licence problem fails a push, not only a release.
- Verified on the published image 2026-10-09 (layer listing): all four files are present (609 KB and
  518 KB of notices; 300 Apache-2.0, 91 MIT, 19 Unicode, 18 ISC, 11 BSD-3, 4 CC0, 2 BSD-2, 1 CDLA
  crates for `key-server`).

### F2 — No build, scan or smoke test before a release tag

**Severity:** Low   **Disposition:** RESOLVED (0.0.2, commits `71df539`, `d7762e0`, `b0c8751`)
**Where:** `.github/workflows/docker-publish.yml` (the only workflow; `on: push: tags: v*`).

**Issue:**

- The Dockerfile is first built at release time; there is no PR or push workflow.
- hadolint and actionlint run only in the tag pipeline.
- There is no configuration scan (Trivy config / Checkov) and no image vulnerability scan of the
  distroless runtime layers or the compiled binaries (IMG lens §C).
- There is no smoke test that the image starts. Useful checks:
  - `key-server` fails cleanly without configuration;
  - `seal-cli --help`;
  - non-root execution confirmed.

**Impact:** a broken or vulnerable image is discovered only after it is published and signed (on
tag), or at contingency time, when it is needed urgently.

**Remediation / evidence:** fixed in `0.0.2`.

- `.github/workflows/ci.yml` runs on every push and pull request and is also the release workflow's
  `verify` job (`workflow_call`), so a tag cannot skip a check. Jobs: hadolint (`Dockerfile`),
  actionlint (digest-pinned), Trivy configuration scan (CRITICAL/HIGH fail), then an amd64 build that
  is not pushed (GHA cache, no registry login), a Trivy image scan (fixable CRITICAL/HIGH fail,
  `ignore-unfixed`, Trivy `v0.74.0` pinned) and `scripts/smoke.sh` (user `65532:65532`, `seal-cli
  --help`, `key-server` exits non-zero without configuration and names `KEY_SERVER_OBJECT_ID`,
  licence files present). Job timeouts added in `d7762e0`.
- The release job scans the published index (`quay.io/…@<digest>`, Trivy, CRITICAL/HIGH fail) **before**
  `cosign sign` and the attestations (`docker-publish.yml`, merge job).
- `.github/workflows/rescan.yml` runs weekly (Monday 06:17 UTC) and rescans `quay.io/…:latest`.
- Evidence of operation: the `v0.0.2` `Publish (Docker)` run (37782631292) succeeded in 14m42s, and
  `CI` on `main` is green on 2026-10-09 (run 37962113785).
- Residual: the CI image job and its smoke test are amd64 only (F16); no `cargo audit` / `cargo deny`
  on the crate graph (F13).

### F3 — Static registry tokens in the jobs that compile third-party code; no credential inventory

**Severity:** Low   **Disposition:** MITIGATED (0.0.2, commit `71df539`); the inventory is a maintainer
item (`OPERATOR_TASKS.md` "Image registry credentials — record scope and rotation", before mainnet)
**Where:** `docker-publish.yml:52-64, :92-104, :133-145` (`docker/login-action` with `QUAY_TOKEN` /
`DOCKERHUB_TOKEN` before `build-push-action`).

**Issue:**

- Both build jobs log in to both registries **before** compiling the upstream workspace, which runs
  hundreds of crate build scripts.
- BuildKit `RUN` steps do not see the runner's Docker credential store, so direct exfiltration from a
  build script is not expected. But the tokens are long-lived, present in the job for its whole
  duration, and not inventoried:
  - which robot account or user they are;
  - their scope (push to this repository only?);
  - when they rotate.
- The base template's §B.2 requires a registry-credentials inventory where OIDC is not possible.

**Impact:** a compromised action, runner or credential leak grants push to the image repositories,
and possibly to every repository the account can reach. Signatures would still identify such an
image as not built by this workflow, but only for consumers that verify.

**Remediation / evidence:**

- Record the credentials in B.2: quay robot account scoped to `seal-key-server` with write; Docker Hub
  access token with "Read & Write" on this repository only; rotation date.
- Build without credentials, exporting to an OCI layout or cache, and push in a short job that logs in
  only to push.
- Keep `id-token: write` only in the merge job (it already is).

Done in `0.0.2`: the `build` job compiles the Rust workspace with no registry login and exports an OCI
archive (`outputs: type=oci`); `ci.yml` has no login either. The `publish-arch` job downloads the
archive and logs in only to `skopeo copy` it, so no third-party code runs while credentials are
present. The `merge-docker-public` job (merge, scan, sign, attest) holds both tokens plus
`id-token: write` and `attestations: write`; it runs pinned actions only (cosign-installer,
sbom-action, attest-build-provenance), no compilation. `id-token` and `attestations` remain only in
that job. Not done: the credential inventory (robot account, scope, rotation date). Registry token
scopes are visible only in the quay and Docker Hub consoles, so this is the maintainer's task, which
`OPERATOR_TASKS.md` already lists with this audit as its decision source.

### F4 — Build-stage apt packages are unpinned

**Severity:** Info   **Disposition:** ACCEPTED-RISK (reason recorded in the Dockerfile, `71df539`)
**Where:** `Dockerfile:16-19` (`# hadolint ignore=DL3008`).

**Issue / Impact:**

- `git`, `ca-certificates`, `clang`, `cmake`, `pkg-config` and `libssl-dev` float with the Debian
  mirror. This affects build reproducibility and the compiler that builds the binaries, not the
  runtime image (only binaries are copied).
- The base image digest pins a snapshot of everything else.

**Remediation / evidence:** either pin versions through `snapshot.debian.org` for the bookworm date
of the base digest, or record the DL3008 exception's rationale in the Dockerfile comment (build-only;
the base digest is pinned).

The second option was taken: `Dockerfile:16-19` now states that the packages float on purpose, affect
only the compiler environment, never the runtime image (binaries and licence texts only), that the base
digest pins everything else and that the source is pinned by tag **and** commit. Accepted because the
runtime image is unaffected, the source is commit-checked and the toolchain image is digest-pinned;
`snapshot.debian.org` pinning would add a moving dependency of its own. The `cargo-about` install in
the `notices` stage is version-pinned (`--locked --version 0.9.2`).

### F5 — Mutable and intermediate tags

**Severity:** Info   **Disposition:** MITIGATED (README and `SECURITY.md` document digest-only
deployment; the kit overlay enforces it; admission verification is part of F8)
**Where:** `docker-publish.yml:73-75, :113-115` (`<sha>-amd64` / `<sha>-arm64` pushed);
`:154-158` (`latest=auto`, `{{major}}.{{minor}}`).

**Issue:**

- The per-architecture build tags stay published. Each points at its own manifest (with build
  attestations), which is not covered by the index-level cosign signature.
- `latest` and `0.0` move with each release.
- Anyone deploying by tag, or pulling an intermediate, bypasses the signed-digest path.

**Remediation / evidence:**

- Delete the intermediate tags after the merge, or push them to a separate staging repository.
- Document "deploy by index digest only" in the README.
- Verify the signature in the deployment kit, for example with a cluster admission policy such as
  sigstore policy-controller or Kyverno `verifyImages`.

Status 2026-10-09: the README ("Deploy by the signed **index digest**, never by tag … The
`<commit>-amd64` / `<commit>-arm64` tags are build intermediates, and `latest` moves") and
`SECURITY.md` ("Verifying an image", with the anchored `cosign verify`) document it. The kit's overlay
references the image by digest from `config/images.yaml` (rendered and checked), so no mutable tag runs
if the kit is used as written; `bootstrap/images/verify-digests.sh` verifies the pinned digest's cosign
signature against the repository's workflow identity. Not done, by choice: the intermediate tags are
still published on both registries (`b0c8751…-amd64/-arm64`, `bea51d96…-amd64/-arm64`, checked
2026-10-09), and `latest` / `0.0` still move (OQ3 stays a maintainer choice; they feed the weekly
rescan, which scans `:latest`). Also, the release scans the merged index after the tags are pushed, so
a failing scan would leave a moved but unsigned `latest`; consumers that verify signatures are
unaffected. Admission-time verification: the platform's sigstore policy-controller runs in warn mode
and covers the `apps` and `registry` namespaces; the kit deploys to `blockchain`, so enforcement there
is part of the F8 activation gate.

### F6 — `seal-cli` (master-seed tooling) ships in the server image

**Severity:** Info   **Disposition:** ADJUDICATED (documented convenience) — with a runbook
requirement
**Where:** `Dockerfile:5-6, :38`; `README.md:14`.

**Issue:**

- The runtime image contains `seal-cli`, which generates the master seed and derives client keys.
  Bundling it is convenient for the contingency runbook.
- It means seed generation can happen inside the cluster, where container stdout is collected by the
  log pipeline. A seed printed to stdout in a pod would be captured in logs.

**Impact:** seed exposure risk depends entirely on how the runbook uses it (F8).

**Remediation / evidence:** the runbook must generate the seed offline (a local `docker run --rm`
with no log shipping, or an air-gapped machine) and store it straight into SOPS. It must never be
generated in-cluster or echoed. Optionally publish a separate `-tools` image.

Status 2026-10-09: the adjudication stands, and the runbook requirement is now written down in both
places. `SECURITY.md` ("A self-hosted key server is custodial") requires generation offline (a local
`docker run --rm` with no log shipping, or an air-gapped machine), direct storage in SOPS, and never
generating or printing the seed in the cluster. The kit runbook step 1 runs `podman run --rm
--entrypoint /usr/local/bin/seal-cli … gen-seed` on the cluster node (outside Kubernetes, so no pod
log pipeline), step 2 backs the seed up before use, and step 5 stores it with SOPS; the kit forbids
pasting it into chat, CI, trackers or the repository. A separate `-tools` image (S3) is not
needed for this. See F8 item 2 for the remaining operator steps.

### F7 — No automated watch for upstream releases or base-image updates

**Severity:** Info   **Disposition:** RESOLVED (0.0.2, commit `71df539`)
**Where:** the repository (no Renovate or Dependabot configuration).

**Issue / Impact:**

- `seal-v0.6.15` is current today (verified).
- Nothing alerts the maintainers to a new upstream release (possibly a security fix), a new Rust
  toolchain, or rebuilt base images carrying CVE fixes.
- For a contingency image, staleness matters at exactly the moment it is needed.

**Remediation / evidence:** add Renovate with Docker digest pinning for both `FROM` lines, and a regex
manager tracking `MystenLabs/seal` releases into `SEAL_TAG` / `SEAL_COMMIT`. The commit check in the
Dockerfile keeps such PRs honest. Pair this with F2's weekly rescan.

Done with Dependabot instead of Renovate: `.github/dependabot.yml` has weekly grouped `docker`
(digest bumps) and `github-actions` updates. The `rust` image is excluded on purpose, because it must
equal the upstream release's `rust-toolchain.toml` and so moves with `SEAL_TAG`. The upstream watch is
the `upstream` job of `rescan.yml` (weekly): it compares `ARG SEAL_TAG` with
`gh api repos/MystenLabs/seal/releases/latest` and opens an issue (deduplicated by title) when they
differ; the vulnerability rescan of the latest image is the `rescan` job. Evidence of operation:
Dependabot runs on 2026-10-08 and the merged Actions bump `4eb832b`. On 2026-10-09 the pinned
`seal-v0.6.15` is the latest upstream release, so no issue is due. The watch does not bump
`SEAL_TAG` / `SEAL_COMMIT` itself; a person updates both after reading the release notes.

### F8 — The deployment kit, master-seed custody and the custodial posture are not reviewable here (pre-deploy gates)

**Severity:** Info for this repository; **blocking before any deployment**
**Disposition:** DEFERRED to the contingency-activation gate (ADR-0002 fallback; `OPERATOR_TASKS.md`
"Mainnet Seal key servers", "two or more decline") and to Section D pre-mainnet. The kit was reviewed
read-only on 2026-10-09 (below); what remains can only be done at activation or by the maintainer.
**Where:** `README.md:38-42` (`post-bootstrap/_contingency/seal-key-server/`, Permissioned mode,
SOPS-stored seed).

**Issue:** everything that determines whether a deployed server is safe lives in the kit. Before a
contingency deployment, each item below must hold, with evidence.

1. **Allowlist = original id.** Permissioned mode allowlists exactly the `seal_policies` **original
   id(s)**: testnet `0x61c4aa…`, plus any superseded namespace whose content must stay decryptable
   (`seal-policies-sui-audit.md` F27 / OQ11). A republish adds a namespace. The client key per package
   is derived with `seal-cli` and recorded.
2. **Seed custody.** The master seed (`MASTER_KEY` env, read by `crates/key-server/src/master_keys.rs`)
   is:
   - generated offline (F6);
   - stored only as a SOPS-encrypted Secret, injected via `secretKeyRef`;
   - never in a ConfigMap or plain manifest;
   - backed up under the custody multisig's process;
   - protected by RBAC denying `get` on that Secret, and on pod specs with the value, to all but
     operators.
3. **Pod security.** `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`,
   drop ALL capabilities, `RuntimeDefault` seccomp; no ephemeral-container or `exec` access for
   non-operators.
4. **Exposure.** Port 2024 behind TLS ingress with rate limiting. Metrics port 9184 cluster-internal
   only. A NetworkPolicy allows egress only to the configured full node.
5. **Deploy by digest.** The image is pinned to the index digest in `config/images.yaml`, with
   signature verification at admission (F5).
6. **On-chain registration.** The key-server object is registered on-chain by a recorded key; its URL
   and public key are documented; seal-ui's `VITE_SEAL_SERVER_OBJECT_IDS_{NET}` is updated.
7. **Custodial disclosure.** `VITE_SEAL_KEY_CUSTODY_{NET}=operator` is set so seal-ui shows the
   custodial notice. The threshold decision is recorded (OQ2): a single self-hosted server is t = 1
   and fully custodial.
8. **Probes and limits** are set, and the health endpoint reveals nothing sensitive.

**Impact:** a mistake in any one of these compromises confidentiality (seed exposure, wrong
allowlist) or availability (lost seed means content sealed to this server is permanently
undecryptable).

**Remediation / evidence:** audit the kit under the IMG lens (pod security, digest deployment) and an
operations runbook review. Record the result here as RESOLVED with the kit commit, or in a separate
audit of the infrastructure workspace.

**Kit review, 2026-10-09 (read-only).** The kit is `post-bootstrap/_contingency/seal-key-server/`
(`README.md`, `base/{configmap,deployment,service,ingress,networkpolicy,kustomization}.yaml`,
`overlays/default/`, `secret.template.yaml`). The workspace is not a git repository, so there is no kit
commit to cite; the review date is the reference. Not applied by `apply.sh` (`_contingency/` is below
its search depth).

| # | Item | Kit state | Result |
| --- | --- | --- | --- |
| 1 | Allowlist = original id | `configmap.yaml`: `server_mode: !Permissioned`, one client (`derivation_index: 0`), `package_ids` = `seal_policies`' original id; both ids are zero placeholders and the server refuses to start with them. Runbook step 4 fills the **mainnet** original id (`Published.toml` `original-id`), notes one-package-per-client and contiguous derivation indices. The kit targets mainnet only, so the superseded testnet namespaces (`0x61c4aa…` and older) are not relevant to it. | holds as a procedure; values filled at activation (the mainnet `seal_policies` is not yet published) |
| 2 | Seed custody | `deployment.yaml`: `MASTER_KEY` from `secretKeyRef` `seal-key-server-seed`; the Secret is not in `kustomization.yaml`; `secret.template.yaml` is a template only; runbook steps 1, 2, 5 (generate on the node with podman, back up offline and via SOPS, apply with `sops -d … \| kubectl apply -f -`). No RBAC manifest denies `get` on the Secret to non-operators, and the multisig custody of the backup is the operator's process (`SECRETS.md`, platform). | partial: no seed exists; RBAC and backup custody are activation-time and platform items |
| 3 | Pod security | `runAsNonRoot`, `runAsUser/Group: 65532`, `seccompProfile: RuntimeDefault`, `automountServiceAccountToken: false`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`, one replica. | holds |
| 4 | Exposure | `ingress.yaml`: only the `/v1/` prefix is routed to port 80 → 2024 (so `/health` and the metrics port are not public); per-IP limit 5r/s, burst 20, reject 429, body 64k; TLS via cert-manager `selfsigned-ca` behind the Cloudflare tunnel. `networkpolicy.yaml`: default-deny ingress; allows `nginx-ingress` → 2024 and `monitoring` → 9184. **Egress is left open** ("the server reads the Sui full node over HTTPS"), not restricted to the full node. `/v1/debug/committee_partial_pk` falls under `/v1/`; upstream answers 400 outside committee mode (checked in `server.rs` at `seal-v0.6.15`). | holds except egress (open by design; ACCEPTED for a contingency kit, tighten at activation) |
| 5 | Deploy by digest | `overlays/default/kustomization.yaml` pins `sha256:8609cbbe…` (stamped by `sync-manifests.sh` from `config/images.yaml`); the rendered image is `quay.io/meddleware-org/seal-key-server@sha256:8609cbbe…`. `base/deployment.yaml` still names the tag `0.0.1`; the overlay's digest overrides it (cosmetic). Admission verification: sigstore policy-controller is warn-mode on `apps` and `registry`, not on `blockchain`. | holds for the pin; admission not covered |
| 6 | On-chain registration | Runbook step 3 registers the derived public key with `key_server::create_and_transfer_v2_independent_server` (mainnet Seal package `0x931739…` per the Seal docs, as the kit states; not re-verified here) and records the object id; step 7 updates `VITE_SEAL_SERVER_OBJECT_IDS_MAINNET`. | procedure present; executed only at activation |
| 7 | Custodial disclosure | Runbook step 7: threshold 2 while an independent server remains; `VITE_SEAL_KEY_CUSTODY_MAINNET=operator` only when this server alone meets the threshold. ADR-0002 states the same. | holds as a decision (OQ2) |
| 8 | Probes and limits | `/health` readiness and liveness probes; requests 50m / 64Mi, limits 1 CPU / 512Mi. `/health` comes from upstream's `get_mysten_service` helper (a liveness answer; not routed publicly). | holds |

Also: the kit documents a localnet rehearsal of 2026-10-02 with the 0.0.1 image (seal, decrypt,
re-seal to another server, decrypt; non-allowlisted packages and foreign client keys refused; lessons
folded into the runbook). That covers S4 on localnet; a testnet rehearsal with 0.0.2 has not been run.

**Remaining before any activation (the gate):** fill the mainnet ids (item 1); create the seed, the
SOPS Secret and RBAC that denies `get` to non-operators, and record the offline backup (item 2);
restrict egress to the full node (item 4); opt the `blockchain` namespace into admission verification
or verify the signature by hand with the `SECURITY.md` command (item 5); register the object (item 6);
decide the threshold and custody variable (item 7, OQ2). A testnet rehearsal of 0.0.2 is advisable
(S4). F8 stays DEFERRED because none of these can be done before the fallback is actually needed.

### F9 — No `SECURITY.md`

**Severity:** Info   **Disposition:** RESOLVED (0.0.2, commit `71df539`)

The repository has no security policy, unlike every other workspace repository. The scope should
cover:

- the image build and publish pipeline: in scope;
- upstream key-server vulnerabilities: report to MystenLabs;
- the deployment kit: the infrastructure workspace.

It should also state the custodial nature of a self-hosted server and the verification commands
(Scope section).

**Remediation / evidence:** `SECURITY.md` now exists. It lists the pipeline and image contents as in
scope, upstream key-server vulnerabilities (to MystenLabs) and the kit / seed custody / on-chain
registration (infrastructure workspace) as out of scope, a private report address with a 3-business-day
acknowledgement, the custodial warning with the offline seed rule (F6), the `cosign verify` command with
the anchored workflow identity and the digest-only rule (F5), and the supported-versions rule (latest
release only; the weekly rescan and upstream watch).

### F10 — Positive: pinned, verified upstream source and a locked build

**Severity:** Positive   **Disposition:** re-verified 2026-10-09 (unchanged at `v0.0.2`)

- `git clone --depth 1 --branch "${SEAL_TAG}"` followed by `test "$(git rev-parse HEAD)" =
  "${SEAL_COMMIT}"` (`Dockerfile:24-25`; `:21-22` at the first pass). The tag cannot move silently.
  Re-verified against upstream 2026-10-09: `seal-v0.6.15` → `d0ab560e…`, the latest release.
- The Rust image `1.96.1` equals upstream `rust-toolchain.toml`, so rustup downloads nothing.
- `cargo build --locked --release --bin key-server --bin seal-cli`: lockfile checksums, only the two
  binaries.
- Multi-stage: only `/out/key-server`, `/out/seal-cli` and the licence texts are copied into the
  runtime stage.
- The one added tool, `cargo-about`, is installed with `--locked --version 0.9.2`.

### F11 — Positive: minimal, non-root, digest-pinned runtime

**Severity:** Positive   **Disposition:** re-verified 2026-10-09 (published image config checked)

- Both `FROM` lines are digest-pinned with their tags kept.
- Runtime is `distroless/cc-debian12:nonroot`: glibc and CA certificates, no shell, no package manager.
- `USER 65532:65532` (`Dockerfile:62`; the published image config shows `65532:65532`).
- No `ENV` secrets and no secret build args; the image's only `ENV` is distroless's `PATH` and
  `SSL_CERT_FILE`.
- OCI labels record the source, version, licence, and upstream tag and commit (F15 for the `v`
  prefix on the version).
- `.dockerignore` keeps `.git`, `.github` and docs out of the context.
- This is markedly harder than upstream's own Dockerfile, which uses unpinned
  `rust:1.90-bullseye` / `debian:bullseye-slim`, runs as root, `apt`-installs PostgreSQL and uses a
  generated bash entrypoint.

### F12 — Positive: publish chain and attestations, verified on the registry

**Severity:** Positive   **Disposition:** re-verified 2026-10-09 for `0.0.2` on both registries

- **Workflow hygiene:**
  - actions SHA-pinned (every `uses:` except the local reusable `ci.yml`); actionlint run by digest;
  - workflow default `contents: read`; `id-token: write` and `attestations: write` only in the merge
    job;
  - `tag == VERSION` gate; the CI checks (hadolint, actionlint, Trivy config, image scan, smoke test)
    run before any release build (F14);
  - native-runner builds per architecture.
- **Signing and attestation:**
  - keyless cosign signing at the **index digest** on both registries;
  - SPDX SBOM generated from the published digest and attested with cosign (its content: F13);
  - GitHub build-provenance attestation pushed to both registries;
  - no `continue-on-error` anywhere (grep of `.github`).
- **Registry evidence (quay.io and Docker Hub, 2026-10-09):** index `sha256:8609cbbe…5497134`
  carries a cosign signature, an SPDX SBOM and SLSA v1 provenance bundle on each registry, every one
  with a Fulcio certificate whose SAN is the publish workflow at `refs/tags/v0.0.2` (issuer GitHub
  Actions) and a Rekor entry. The first pass saw the same three bundles on `0.0.1` (Docker Hub only).

### F13 — The SBOM and the image scan do not see the compiled Rust crate graph

**Severity:** Low   **Disposition:** DEFERRED to the pre-mainnet scan gate (Section D: "image and
configuration scans clean at the review date"; contingency activation is mainnet-only). Fix is a CI
and Dockerfile change that this alignment did not make.
**Where:** `Dockerfile:41-44` (`cargo build --locked --release`); `docker-publish.yml` (SBOM from the
published image with `anchore/sbom-action`); `ci.yml` / `rescan.yml` (Trivy image scans).

**Issue:**

- The decoded SPDX SBOM of `0.0.2` lists 12 packages: the distroless OS packages (`base-files`,
  `ca-certificates`, `libc6`, `libssl3`, `tzdata`, …) and the image itself. No Rust crate appears.
- The `key-server` binary carries no `cargo-auditable` section (`.dep-v0`), so neither the SBOM tool nor
  Trivy can read its dependencies from the image. The image scans therefore cover the base layers,
  not the several hundred crates compiled into the binaries.
- The IMG lens requires the SBOM to list the dependencies actually compiled into the image, and the Rust
  lens B.1 requires `cargo audit` and `cargo deny` results. Upstream ships a `deny.toml`, and the
  licence notices already read the upstream `Cargo.lock` (F1), but no advisory check runs on it.

**Impact:** a known vulnerability in a linked crate is not seen by CI or the weekly rescan. The upstream
watch (F7) is the only signal, and it fires on a new upstream release, not on an advisory. No impact
today: the image is not deployed, and the base-layer scans and licence gate work.

**Remediation / evidence:** not fixed. Options: build with `cargo auditable build` (pinned) so Trivy and
the SBOM read the embedded list; or run `cargo audit` / `cargo deny check advisories` (pinned) against
the checked-out upstream `Cargo.lock` in the CI image job, with an expiring allowlist (S5). Until then,
read the upstream release notes and RustSec before activating the image (F8).

### F14 — Positive: release gate equals CI, credential-less builds, fail-closed licences

**Severity:** Positive   **Disposition:** new 2026-10-09 (the fixes of F1–F3, F7 seen together)

- The tag workflow calls `ci.yml` on the tagged commit (`verify`, `uses: ./.github/workflows/ci.yml`),
  and `build` needs it; the base §B.2 "release gate equals CI" row holds.
- The Rust compile happens in jobs with no registry login and no `id-token`; the job that holds the
  tokens only copies archives (F3).
- The Trivy image scan runs before cosign in the release job, in CI before any push, and weekly after
  release (F2).
- The licence step fails the build on an unaccepted licence, so an upstream bump cannot add one
  silently (F1).
- All actions are SHA-pinned and kept current by grouped Dependabot PRs (F7); `4eb832b` is the latest.

### F15 — The image `version` label carries `v0.0.2`, not `0.0.2`

**Severity:** Info   **Disposition:** ACCEPTED-RISK (cosmetic; fix with the next release)
**Where:** `docker-publish.yml` build job (`build-args: VERSION=${{ github.ref_name }}`);
`Dockerfile:52` (`org.opencontainers.image.version="${VERSION}"`).

**Issue:** the label is built from the git ref name, so the published image reports
`org.opencontainers.image.version` = `v0.0.2` (checked in the image config), while the tags, `VERSION`
and `config/images.yaml` say `0.0.2`. The README "Checks" paragraph also has a garbled sentence ("the
and an amd64 build"). Neither affects security or deployment (the kit pins the digest).

**Remediation / evidence:** pass `${{ github.ref_name }}` with the `v` stripped (as the `version` job
already does for the tag check) at the next release. Accepted: label only; no consumer reads it.

### F16 — arm64 is built but not scanned or smoke-tested before release

**Severity:** Info   **Disposition:** ACCEPTED-RISK
**Where:** `ci.yml` image job (`platforms: linux/amd64`); `docker-publish.yml` Trivy step on the merged
index.

**Issue:** CI builds, scans and smoke-tests only amd64. The release builds arm64 natively from the same
Dockerfile and lockfile and attests it, but the Trivy step on the merged index scans the runner's
platform (amd64), and `smoke.sh` is not run on arm64.

**Remediation / evidence:** accepted for a contingency image: the source, lockfile, toolchain and base
digest are identical for both architectures, and the arm64 manifest carries the same signature and
provenance. If an arm64 node is ever used, run `smoke.sh` on it first (it takes an image reference).
A native arm64 CI job would remove the gap.

---

## Section A — Invariant verification matrix

| # | Invariant (IMG / SEAL) | Enforced at | Proven by | Status |
| --- | --- | --- | --- | --- |
| A1 | Every `FROM` digest-pinned; runtime minimal | `Dockerfile:13, :46` | review; published image config | HOLDS |
| A2 | Build context excludes VCS, CI and docs; only named files are copied from it | `.dockerignore`; `COPY about.toml about.hbs`, `COPY LICENSE` | review | HOLDS |
| A3 | Reproducible build: locked deps, pinned toolchain and tools | `cargo --locked`; Rust 1.96.1 digest; `cargo-about` `--locked --version 0.9.2` | upstream toolchain file matched | HOLDS for Rust and tools; apt unpinned with a recorded reason (F4) |
| A4 | Upstream source cannot move under the tag | commit check `Dockerfile:24-25` | `ls-remote` re-verification 2026-10-09 | HOLDS |
| A5 | No secrets in any layer or arg | Dockerfile, workflow `build-args` (`VERSION` only) | review; image config `Env` has only `PATH`, `SSL_CERT_FILE` | HOLDS |
| A6 | Non-root runtime | `USER 65532:65532` (`Dockerfile:62`) | image config checked; `scripts/smoke.sh` asserts it in CI | HOLDS |
| A7 | Every pushed image signed, with SBOM and provenance, at the index digest | merge job | referrers on quay.io and Docker Hub decoded 2026-10-09 (3 bundles each, SAN = publish workflow) | HOLDS on both registries; intermediates unsigned (F5) |
| A8 | Pre-release build, scan and smoke test | `ci.yml`, called by the release | green runs; F2 | HOLDS (amd64; F16) |
| A9 | Redistribution licence obligations | `notices` stage; `about.toml` | layer listing of the published image | HOLDS |
| A10 | Pod security, probes, limits, deploy-by-digest | the kit | read 2026-10-09 (F8 items 3, 5, 8) | HOLDS in the kit; egress open and admission not covering `blockchain` (F8) |
| A11 | Permissioned allowlist = policy original id; seed custody; custodial disclosure | the kit + seal-ui | kit procedure read (F8 items 1, 2, 7) | procedure present; values and seed custody are activation-time (F8) |
| A12 | The SBOM and scans cover the dependencies compiled into the image | SBOM action, Trivy | decoded SBOM (12 OS packages), no `.dep-v0` section | **GAP** (F13) |
| A13 | The release gate runs the same checks as CI | `verify` job in `docker-publish.yml` | workflow read | HOLDS (F14) |
| A14 | No registry credential is present while third-party code compiles | `build` job has no login; `publish-arch` logs in to push only | workflow read | HOLDS (F3) |

---

## Section B — Supply-chain, publish-authority & capability matrix

### B.1 Dependency & CVE risk

| Dependency | Pinned | Liveness dependency? | CVE / scan status | Notes |
| --- | --- | --- | --- | --- |
| MystenLabs/seal `seal-v0.6.15` | tag + commit `d0ab560e…` | the whole server | upstream; still the latest release (2026-10-09) | Apache-2.0 (F1); weekly upstream watch (F7) |
| Upstream crate graph | upstream `Cargo.lock` (committed upstream), `--locked` | compiled in | **not scanned** — no `cargo audit` / `cargo deny`, not in the SBOM (F13) | upstream `deny.toml` exists; licences gated by `about.toml` (F1) |
| `rust:1.96.1-slim-bookworm` | digest | build | build stage only; not in the runtime image | excluded from Dependabot by design (moves with `SEAL_TAG`) |
| Debian packages (build) | unpinned, accepted (F4) | build | — | not in runtime |
| `distroless/cc-debian12:nonroot` | digest | runtime (glibc, CA) | Trivy image scan in CI, release and weekly rescan (fixable CRITICAL/HIGH fail) | Dependabot digest PRs (F7) |
| `cargo-about` 0.9.2 | `--locked --version` | build | — | licence notices only |
| Scanner | Trivy `v0.74.0` (`trivy-action` SHA-pinned) | CI | green 2026-10-09 | config and image scans |
| Full node, key-server object, ingress | kit | runtime | — | F8 |

### B.2 Publish authority, capabilities & secret custody

| Authority / secret | Where | Custody | Gates | Rotation |
| --- | --- | --- | --- | --- |
| `QUAY_USERNAME` / `QUAY_TOKEN` | Actions secrets | **static**; only the `publish-arch` and merge jobs; inventory is a maintainer item (F3, `OPERATOR_TASKS.md`) | push to quay.io | unrecorded |
| `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` | Actions secrets | **static**; same jobs; inventory as above | push to Docker Hub | unrecorded |
| Cosign / attestation signing | GitHub OIDC → Fulcio (keyless) | ephemeral | signatures, SBOM, provenance | n/a |
| Key-server master seed | kit: SOPS Secret (not yet created) | kit runbook (F8); no seed exists | every key this server derives | rotation means a new key-server object and re-sealing |

#### CI & release integrity

| Item | Holds? | Evidence |
| --- | --- | --- |
| Actions pinned | Yes | SHA pins on every external `uses:`; actionlint by digest; Dependabot keeps them current |
| Least privilege | Yes | workflow `contents: read`; OIDC and attestations only in merge |
| OIDC instead of long-lived tokens | **Partly** | signing is keyless; registry pushes use static tokens, now confined to the push and merge jobs (F3) |
| Tag-gated, version-checked | Yes | `v*` and `tag == VERSION` |
| Images: digest-pinned bases, non-root, signed, SBOM, provenance | Yes | F10–F12 |
| Secrets never echoed | Yes | review |
| Release gate equals CI | Yes | `verify` calls `ci.yml` (F14) |
| Pre-release verification | Yes | F2 (arm64 residual F16) |

### B.IMG-1 Publish & attestation

| Registry | Index digest | Signature | SBOM attestation | Provenance | Verified |
| --- | --- | --- | --- | --- | --- |
| docker.io/meddleware/seal-key-server | `sha256:8609cbbe…5497134` (0.0.2) | cosign (`sign/v1`) | SPDX (`spdx.dev/Document`; 12 OS packages — F13) | SLSA v1 | yes: referrers decoded 2026-10-09, SAN = `docker-publish.yml@refs/tags/v0.0.2`, one Rekor entry each |
| quay.io/meddleware-org/seal-key-server | `sha256:8609cbbe…5497134` (same index) | cosign (`sign/v1`) | SPDX | SLSA v1 | yes: same check 2026-10-09; `verify-digests.sh` (cosign) 16/16 valid |
| both (superseded 0.0.1) | `sha256:e884712d…7465` | cosign | SPDX | SLSA v1 | Docker Hub decoded 2026-10-03 (SAN not checked then) |

### B.SEAL-1 Committee readiness (contingency)

| Item | State |
| --- | --- |
| Who operates | Meddleware (custodial) — only on contingency. Normal operation: Overclock, NodeInfra and H2O Nodes, Open mode, 2-of-3 (D24). |
| How the set and threshold change | seal-ui env (`VITE_SEAL_SERVER_OBJECT_IDS_{NET}`, `VITE_SEAL_THRESHOLD`, `VITE_SEAL_KEY_CUSTODY_{NET}=operator`); kit runbook step 7 |
| Existing ciphertexts | Stay bound to the servers in their headers. Content sealed to the independent committee is **not** decryptable by this server; switching servers needs re-sealing (seal-client `describeCiphertext`; seal-ui's re-seal action) while the old servers are still reachable. |
| Permissioned allowlist | Must be the `seal_policies` original id(s) (F8) |

### B.AUTH-1 Key & credential inventory (AUTH lens, key material only)

| Key / credential (name only) | Type / algorithm | Where held | Who can read it | Rotation cadence · last rotated | Compromise procedure |
| --- | --- | --- | --- | --- | --- |
| `MASTER_KEY` (key-server master seed) | master seed from `seal-cli gen-seed` (derived client keys are BLS12-381) | not created; at activation a SOPS Secret `seal-key-server-seed` (kit step 5) plus an offline backup (step 2) | cluster operators (RBAC to be added — F8); anyone with the age key | none planned: rotation means a new key-server object and re-sealing · n/a | new seed, new `KeyServer` object, re-seal content; the leaked seed decrypts everything it served |
| Client key 0 (derived, index 0) | derived from the seed | derived in memory by the server; its public key is on-chain | the seed holder | with the seed | as above |
| Registering address of the `KeyServer` object | Sui key | the custody multisig if one exists (kit step 3) | its signers | n/a · n/a | transfer or update the object; the owner can change the URL |
| `QUAY_TOKEN`, `DOCKERHUB_TOKEN` | registry access tokens | GitHub Actions secrets | repository admins; the push and merge jobs | unrecorded — `OPERATOR_TASKS.md` "Image registry credentials" | revoke in the registry console; re-publish; consumers verify signatures |
| SOPS age key | age | cluster node (platform; `SECRETS.md`) | node operator | platform audit | platform audit |

---

## Section C — Test-coverage & hermetic/live split

### C.1 Coverage grade — C (CI build, scans and a smoke test; no behavioural tests of the server)

| Dimension | Assessment |
| --- | --- |
| Build | built on every push and PR (amd64) and on release (both architectures); notices stage included |
| Static checks | hadolint, actionlint, Trivy configuration scan on every push and PR |
| Scans | Trivy image scan before push (CI), before signing (release) and weekly; fixable CRITICAL/HIGH fail; crate graph not covered (F13) |
| Runtime | `scripts/smoke.sh`: user `65532:65532`, `seal-cli --help`, `key-server` refuses to start without configuration naming `KEY_SERVER_OBJECT_ID`, licence files present; no probe test of a configured server (kit rehearsal only) |

### C.2 Hermetic vs. live paths

| Path | Hermetic? | Deferred to | Tracking |
| --- | --- | --- | --- |
| Image build, scan, non-root execution, start-up refusal | yes (CI, no network beyond the build) | — | F2 |
| Key-server behaviour (Permissioned mode, allowlist, key derivation) | no | upstream tests; the kit's localnet rehearsal of 2026-10-02 (0.0.1); a testnet rehearsal of 0.0.2 is not run | F8, S4 |
| Signature and attestation verification | no | operator commands (Scope); `verify-digests.sh` | F5 |

---

## Section D — Deployment-readiness gates

### pre-localnet

- [x] every `FROM` digest-pinned; `.dockerignore` present; no context secrets — A1, A2
- [x] locked dependency install; pinned toolchain; artifact-only runtime copy — A3 (apt: F4, accepted)
- [x] no secrets in `ARG` / `ENV` / `COPY` / `RUN` — A5

### pre-testnet *(contingency rehearsal)*

- [x] non-root runtime — A6
- [x] pod security context, probes and limits (kit) — read 2026-10-09: F8 items 3, 8
- [x] deployment by digest from `config/images.yaml` — the overlay renders `@sha256:8609cbbe…` (F8 item 5)
- [ ] admission-time signature verification in the kit's namespace (or a manual `cosign verify` at
  activation) — F5, F8; activation-time, maintainer
- [ ] Permissioned allowlist = `seal_policies` original id(s); client keys recorded — F8 item 1; the
  mainnet `seal_policies` is not published yet, so this is filled at activation (mainnet-blocked)
- [x] pre-release build, scan and smoke CI — F2
- [ ] a testnet rehearsal of `0.0.2` (the localnet rehearsal of 2026-10-02 used `0.0.1`) — S4;
  maintainer

### pre-mainnet

- [x] signature, SBOM attestation and provenance on every pushed image (both registries decoded
  2026-10-09; `verify-digests.sh` 16/16) — F12
- [ ] image and configuration scans clean at the review date — config and base-layer image scans are
  green (CI 2026-10-09); the crate graph is not covered — F13 (mainnet-blocked: contingency is a
  mainnet fallback)
- [x] licence texts shipped — F1
- [ ] master-seed custody, backup and rotation runbook reviewed; custodial disclosure and threshold
  decided — the runbook was read 2026-10-09 (F8); the seed, RBAC, offline backup and the OQ2 decision
  are activation-time and maintainer items
- [ ] registry credentials inventoried and scoped — `OPERATOR_TASKS.md` "Image registry credentials"
  (maintainer, before mainnet) — F3
- [ ] external review of the kit — maintainer, before mainnet

---

## Cross-project themes

- **Supply chain & release integrity:**
  - the strongest image pipeline pattern in the workspace: a commit-checked upstream, digest-pinned
    bases, distroless non-root, credential-less builds, release gate equal to CI, a Trivy scan before
    signing, index-level keyless signing, an SBOM and provenance, shipped licence notices (F14);
  - missing pieces: the credential inventory (F3, maintainer) and visibility of the compiled crate
    graph in the SBOM and scans (F13).
- **Wire-format coupling:** none in this repository. The Seal protocol coupling between this server
  version and `@mysten/seal` in seal-client is upstream's compatibility promise. Re-verify against
  seal-client's SDK version when bumping `SEAL_TAG`.
- **On-chain-truth boundary:** a self-hosted key server is an off-chain custodian of decryption power.
  The on-chain policies still gate key release, but the operator can bypass them with the seed.
  ADR-0002's choice of independent operators (mainnet: Overclock, NodeInfra, H2O Nodes, Open mode,
  2-of-3 — D24) is what keeps Sealed Storage non-custodial; this image is its documented exception.
- **Deployment readiness:** Section D; F8 is the gate. The kit was read on 2026-10-09 and its pod
  security, exposure, probes and digest pinning hold; seed custody, ids and registration are
  activation-time.
- **Chain-access layering (ADR-0001):** n/a. The server reads the chain through its configured full
  node (the kit omits `node_url`, so upstream's public mainnet full node is used).
- **Package ids (Seal/Sui lenses):** this repository holds none. The kit records the mainnet Seal
  package used for registration (`0x931739…`, taken from the Seal docs; not re-verified here) and
  leaves the `seal_policies` original id and the `KeyServer` object id as placeholders until
  activation. The current testnet `seal_policies` is `0x0c8f7349…`; the earlier `0x61c4aa…` is
  superseded and immutable.
- **Pre-v0.2 policy:** image version 0.0.2 (patch-only bumps until mainnet). The next release is
  0.0.3; no compatibility shims apply.

---

## Normative requirements (MUST / MUST NOT)

1. MUST ship the upstream licence and third-party notices with the redistributed binaries — **holds**
   (F1).
2. MUST build, scan and smoke-test the image before a release is signed and published — **holds**
   (F2; arm64 residual F16).
3. MUST inventory and scope every non-OIDC registry credential — **does not hold yet**: the builds no
   longer hold the tokens, but the inventory is a maintainer item (F3, `OPERATOR_TASKS.md`).
4. MUST NOT deploy the image until every F8 gate holds, with evidence recorded — **holds** (not
   deployed).
5. MUST deploy by index digest with signature verification, never by a mutable tag — the overlay
   pins the digest and `verify-digests.sh` verifies the signature; admission enforcement in the kit's
   namespace is an activation item (F5, F8).
6. MUST list the dependencies compiled into the image in its SBOM and scan them for advisories —
   **does not hold** (F13).

**IMG lens baseline:**

| ID | Holds? | Evidence |
| --- | --- | --- |
| IMG-M1 | yes | A1 |
| IMG-M2 | yes | A2 |
| IMG-M3 | yes for Rust and tools; apt unpinned in the build stage, accepted | F4 |
| IMG-M4 | yes | A5 |
| IMG-M5 | image yes; pod context in the kit holds (read 2026-10-09) | F8 item 3 |
| IMG-M6 | yes in the kit (overlay renders the digest from `config/images.yaml`) | F8 item 5 |
| IMG-M7 | yes (both registries verified 2026-10-09) | F12 |
| IMG-M8 | scan before signing: yes; licence notices: yes; verification command pinned to the workflow: yes (`SECURITY.md`); SBOM lists compiled dependencies: **no** | F2, F1, F9, F13 |

**SEAL lens baseline (key-server side):**

| ID | Holds? | Evidence |
| --- | --- | --- |
| SEAL-M4 | a single self-hosted server gives no confidentiality beyond one operator; the kit keeps t = 2 while an independent server remains; decision recorded as OQ2 | F8 item 7 |
| SEAL-M8 | the kit's allowlist must name the original id; the policy UpgradeCap's power over existing content is noted in `seal-policies-sui-audit.md` | F8 item 1 |
| SEAL-M1–M3, M5–M7 | N/A (client-side) | — |

**RUST lens (build-scoped) and AUTH lens (key material):**

| ID | Holds? | Evidence |
| --- | --- | --- |
| RS B.1 (`cargo audit` and `cargo deny` in CI) | no (not run on the upstream lockfile) | F13 |
| RS B.RS-1 (locked build, pinned toolchain, image per IMG) | yes | A3, F10 |
| RS-M1–M9 | N/A (upstream code) | — |
| AUTH-M2 (keys in a secret store, not source, env literals or logs) | as a procedure: `secretKeyRef` from a SOPS Secret, offline generation, never printed; no seed exists | F6, F8 item 2 |
| AUTH-M1, M3–M11 | N/A (no tokens, IdP or clients) | — |

## Implementation suggestions (SHOULD / MAY)

- **S1** Renovate for the base digests and the upstream tag and commit — done differently: Dependabot
  for digests and Actions, and the weekly upstream-release watch (F7).
- **S2** SHOULD add an admission policy (sigstore policy-controller or Kyverno) requiring this
  workflow's identity for the image, in the namespace the kit uses (F5, F8).
- **S3** MAY publish a separate `-tools` image with `seal-cli`, keeping the server image to
  `key-server` only — not pursued; F6 is adjudicated with the offline-seed rule.
- **S4** SHOULD document and run a contingency rehearsal on testnet with `0.0.2`: deploy to a test
  namespace, register a test key-server object, decrypt a time-lock item through seal-client, then tear
  down (F8). The localnet rehearsal of 2026-10-02 (0.0.1) is in the kit README.
- **S5** SHOULD run `cargo audit` and upstream's `cargo deny check` (pinned) against the checked-out
  upstream `Cargo.lock` in CI, with an expiring allowlist (F13).
- **S6** SHOULD build with `cargo auditable` (pinned) so the SBOM and Trivy can read the crate list
  from the binaries (F13).
- **S7** MAY run `smoke.sh` on a native arm64 runner (F16), and strip the `v` from the `VERSION` build
  argument (F15).

## Open questions (`OQ#`)

1. **OQ1** Should the deployment kit be audited as part of this repository's audit (by referencing a
   kit commit), or as its own audit in the infrastructure workspace? *Answered in practice 2026-10-09:*
   this pass read the kit and recorded the result in F8 by date (the workspace is not a git
   repository, so there is no commit to cite). A separate platform-level review of the cluster side
   (RBAC, egress, admission, SOPS key) stays with the platform audit; the maintainer may confirm or
   move the kit review there.
2. **OQ2** On contingency, does Meddleware run one server (t = 1, fully custodial) or several
   independently operated ones? Is the custodial notice in seal-ui sufficient disclosure for users
   whose content was sealed under the independent committee and must be re-sealed? *Open
   (maintainer):* the kit and ADR-0002 prepare t = 2 with a remaining independent server and the
   custody notice only when this server alone meets the threshold; the final decision is taken at
   activation (`OPERATOR_TASKS.md` "Mainnet Seal key servers").
3. **OQ3** Should `latest` and `{major}.{minor}` tags be published at all for a security-critical,
   digest-deployed image (F5)? *Open (maintainer):* they are still published and feed the weekly
   rescan; deployment is by digest.
4. **OQ4** Keep both registries? Each adds a static credential (F3) and a verification target. *Open
   (maintainer):* both are still published, signed and verified identically.

## Risks

- **Custody:** a deployed server's operator, or anyone with the seed, can decrypt everything sealed
  to it. This is acceptable only as a disclosed contingency.
- **Upstream trust:** the image is as trustworthy as MystenLabs/seal at the pinned commit and its
  crate graph, whose advisories are not checked here (F13).
- **Staleness at need:** a contingency image built long before use may carry known vulnerabilities;
  mitigated by the weekly rescan and upstream watch (F2, F7), but only for base layers and releases,
  not crate advisories (F13).
- **Seed loss:** content sealed to this server becomes permanently undecryptable if the seed is lost.
- **Activation under pressure:** the placeholders, seed, RBAC, egress policy and admission check are
  all activation-time work (F8); a rehearsal on testnet with the current image is the mitigation (S4).

---

## Re-verification log

- 2026-10-03 — first-pass baseline at `bea51d9` (tag `v0.0.1`).
  - **Lenses:** AUDIT_TEMPLATE.md (2026-10-02) + IMG (2026-09-30) + SEAL (2026-09-30, key-server
    side).
  - **Verified:**
    - the upstream tag → commit and that it is the latest release;
    - the toolchain match and the upstream licence file;
    - the Docker Hub tags and digests;
    - the OCI referrers: three Sigstore bundles (signature, SPDX SBOM, SLSA provenance) at the index
      digest.
  - **Not checked:**
    - the certificate identity (Docker Hub anonymous rate limit);
    - quay.io (egress blocked);
    - a local build or run (no Docker daemon);
    - the deployment kit (not available).
  - **Recorded:** F1–F12; OQ1–OQ4.
  - **No findings resolved:** by maintainer instruction this pass only records findings. Remediation,
    including single-solution fixes under the resolve-inline rule, is to be applied separately, with
    each disposition moved to RESOLVED and the diff cited.
- 2026-10-09 — alignment with the code at HEAD `4eb832b` (release `v0.0.2` = `b0c8751`; the 0.0.2
  fixes are commit `71df539` and follow-ups `563856a`, `9af9b45`, `d7762e0`, `b0c8751`).
  - **Lenses:** AUDIT_TEMPLATE.md (2026-10-08) + IMG (2026-10-08) + SEAL (2026-09-30, key-server
    side) + RUST (2026-10-08, build-scoped) + AUTH (2026-10-08, key material). RUST and AUTH were added
    to the Template line; OPS and PLATFORM stay not triggered. The missing **Deployment status**
    front-matter line was added.
  - **Dispositions:** F1 DEFERRED → RESOLVED; F2 DEFERRED → RESOLVED; F3 DEFERRED → MITIGATED (builds
    credential-less; the inventory is `OPERATOR_TASKS.md`); F4 → ACCEPTED-RISK (reason in the
    Dockerfile); F5 → MITIGATED; F6 ADJUDICATED (confirmed); F7 DEFERRED → RESOLVED (Dependabot and
    the weekly watch); F8 stays DEFERRED to the activation gate, now with a per-item kit review; F9
    DEFERRED → RESOLVED (`SECURITY.md`); F10–F12 re-verified for 0.0.2.
  - **Added:** F13 (SBOM and scans blind to the crate graph, DEFERRED to the pre-mainnet scan gate),
    F14 (Positive), F15 (label `v` prefix, ACCEPTED-RISK), F16 (arm64 not smoke-tested,
    ACCEPTED-RISK). Section A gained A12–A14; B.AUTH-1 added; the RUST and AUTH rows added to the
    normative lists. Final count: 4 RESOLVED, 2 MITIGATED, 1 ADJUDICATED, 3 ACCEPTED-RISK, 2 DEFERRED,
    4 Positive.
  - **Verified (new):**
    - both registries serve the same `0.0.2` index `sha256:8609cbbe…`, equal to
      `config/images.yaml` and the overlay; image config `User` `65532:65532`;
    - referrers on both registries decoded: cosign, SPDX and SLSA bundles per registry, every
      certificate SAN `docker-publish.yml@refs/tags/v0.0.2`, issuer GitHub Actions, one Rekor entry
      each. The cosign signature was not re-verified cryptographically here (no `cosign` binary);
      `verify-digests.sh` passed 16/16 on the same day;
    - the SBOM has 12 OS packages and no crates; `key-server` has no `.dep-v0` section (F13);
    - the four licence files are in the amd64 layers (F1);
    - upstream `seal-v0.6.15` still the latest release; `CI` and `Publish (Docker)` runs green;
    - the kit read in full and `kubectl kustomize` render checked (F8).
  - **Not verified:** a local build or run of the image (CI is the evidence); an arm64 run; the mainnet
    Seal package id in the kit (`0x931739…`, from the Seal docs); `/health`'s response body (the route
    comes from upstream's `get_mysten_service`); registry token scopes (console only — F3).
  - **Observed, no action here:** the Dockerfile comment says CI builds `--target notices` alone, but
    `ci.yml` builds the whole image (which includes the stage); the kit's `base/deployment.yaml` still
    names tag `0.0.1` (the overlay's digest wins).

## Pre-save consistency checklist (this pass)

- [x] Section A ↔ findings: GAP row A12 (F13); A8, A9, A13, A14 hold; A10–A11 point to F8.
- [x] Finding header ↔ body: consistent.
- [x] Template line: base + IMG + SEAL (scoped) + RUST (build-scoped) + AUTH (key material) with
  dates; untriggered lenses named with reasons.
- [x] Closing four-part structure present.
- [x] Section D ↔ dispositions (unticked items name their gate or the maintainer item).
- [x] Executive summary ↔ dispositions and ceiling (realised Low); counts match.
- [x] C.1 reflects the CI build, scans and smoke test.
- [x] Re-verification log entry added (2026-10-09).
