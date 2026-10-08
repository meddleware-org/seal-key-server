#!/usr/bin/env bash
# Smoke test of a built seal-key-server image: bash scripts/smoke.sh <image>
#
# Checks what a contingency deployment needs on day one, without any configuration or network:
#   - the image runs as the distroless nonroot user;
#   - seal-cli starts;
#   - key-server refuses to start without configuration (and says why) instead of hanging or serving;
#   - the licence texts are in the image.
set -euo pipefail

image="${1:?usage: smoke.sh <image>}"

user="$(docker image inspect --format '{{.Config.User}}' "$image")"
if [ "$user" != "65532:65532" ]; then
  echo "image runs as '${user}', want 65532:65532" >&2
  exit 1
fi

docker run --rm --entrypoint /usr/local/bin/seal-cli "$image" --help > /dev/null

code=0
out="$(timeout 120 docker run --rm "$image" 2>&1)" || code=$?
if [ "$code" -eq 0 ] || [ "$code" -eq 124 ]; then
  echo "key-server without configuration exited ${code}; want a clean non-zero exit" >&2
  echo "$out" >&2
  exit 1
fi
if ! grep -q 'KEY_SERVER_OBJECT_ID' <<< "$out"; then
  echo "key-server's refusal does not name the missing setting:" >&2
  echo "$out" >&2
  exit 1
fi

tmp="$(mktemp -d)"
cid="$(docker create "$image")"
trap 'docker rm -f "$cid" > /dev/null; rm -rf "$tmp"' EXIT
for f in LICENSE-seal LICENSE-seal-key-server THIRD_PARTY_LICENSES-key-server.txt THIRD_PARTY_LICENSES-seal-cli.txt; do
  docker cp "${cid}:/usr/share/doc/seal-key-server/${f}" "${tmp}/${f}"
  if [ ! -s "${tmp}/${f}" ]; then
    echo "licence file ${f} is empty" >&2
    exit 1
  fi
done

echo "smoke test passed"
