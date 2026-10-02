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
FROM docker.io/library/rust:1.96.1-slim-bookworm@sha256:e18a79fc84dfcfc3ab5ba72290398a644c135c97eaa881447fddc354ee4701a3 AS build
ARG SEAL_TAG
ARG SEAL_COMMIT
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates clang cmake pkg-config libssl-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch "${SEAL_TAG}" https://github.com/MystenLabs/seal.git . \
 && test "$(git rev-parse HEAD)" = "${SEAL_COMMIT}"
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
# 65532 is distroless's nonroot user.
USER 65532:65532
# 2024: key-server API; 9184: Prometheus metrics.
EXPOSE 2024 9184
ENTRYPOINT ["/usr/local/bin/key-server"]
