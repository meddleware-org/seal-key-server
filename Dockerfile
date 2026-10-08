# Contingency image of the upstream MystenLabs/seal key server (workspace ADR-0002: never deployed
# unless the independent key servers become unavailable). Built from a pinned release tag whose commit
# is checked, so the source cannot move under the tag.
#
# Binaries: /usr/local/bin/key-server (entrypoint) and /usr/local/bin/seal-cli (master-seed and
# client-key tooling for the runbook: `--entrypoint /usr/local/bin/seal-cli`).
# Runtime: distroless cc (glibc + CA certificates), non-root, no shell.

ARG SEAL_TAG=seal-v0.6.15
ARG SEAL_COMMIT=d0ab560e8dfffe31397728fe284936085a7a7100

# Rust 1.96.1 matches the release's rust-toolchain.toml, so rustup downloads nothing.
FROM docker.io/library/rust:1.96.1-slim-bookworm@sha256:e18a79fc84dfcfc3ab5ba72290398a644c135c97eaa881447fddc354ee4701a3 AS source
ARG SEAL_TAG
ARG SEAL_COMMIT
# Build-stage packages float with the Debian mirror on purpose (hadolint DL3008): they only affect the
# compiler environment, never the runtime image (which receives binaries and licence texts only), the base
# image digest above pins everything else, and the release pins the source by tag AND commit below.
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates clang cmake pkg-config libssl-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch "${SEAL_TAG}" https://github.com/MystenLabs/seal.git . \
 && test "$(git rev-parse HEAD)" = "${SEAL_COMMIT}"

# Licence texts of every crate linked into each binary (Apache-2.0 §4(a) and the MIT/BSD notice
# clauses). `cargo about generate --fail` stops the build when a dependency carries a licence that
# about.toml does not accept, so an upstream bump cannot silently add one. CI builds this target alone
# (`--target notices`) so a licence problem shows up without a full compile.
FROM source AS notices
RUN cargo install --locked --version 0.9.2 --features cli cargo-about
COPY about.toml about.hbs /about/
RUN mkdir -p /out \
 && for crate in key-server seal-cli; do \
      cargo about generate --locked --fail -c /about/about.toml \
        --manifest-path "crates/${crate}/Cargo.toml" /about/about.hbs > "/out/THIRD_PARTY_LICENSES-${crate}.txt"; \
    done \
 && cp LICENSE /out/LICENSE-seal

FROM source AS build
RUN cargo build --locked --release --bin key-server --bin seal-cli \
 && install -D -m 0755 target/release/key-server /out/key-server \
 && install -D -m 0755 target/release/seal-cli /out/seal-cli

FROM gcr.io/distroless/cc-debian12:nonroot@sha256:9dac0a79194e45a7da0158a9c6da57b217585af0786db3845d1f0ec1a0dd182f
ARG SEAL_TAG
ARG SEAL_COMMIT
ARG VERSION=dev
LABEL org.opencontainers.image.title="seal-key-server" \
      org.opencontainers.image.description="MystenLabs Seal key server (contingency image; Permissioned mode)" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="https://github.com/meddleware-org/seal-key-server" \
      org.opencontainers.image.licenses="Apache-2.0" \
      io.meddleware.seal.tag="${SEAL_TAG}" \
      io.meddleware.seal.commit="${SEAL_COMMIT}"
COPY --from=build /out/key-server /out/seal-cli /usr/local/bin/
# Licence of the redistributed Apache-2.0 software and the notices of its dependencies (README: "Licences").
COPY --from=notices /out/ /usr/share/doc/seal-key-server/
COPY LICENSE /usr/share/doc/seal-key-server/LICENSE-seal-key-server
# 65532 is distroless's nonroot user.
USER 65532:65532
# 2024: key-server API; 9184: Prometheus metrics.
EXPOSE 2024 9184
ENTRYPOINT ["/usr/local/bin/key-server"]
