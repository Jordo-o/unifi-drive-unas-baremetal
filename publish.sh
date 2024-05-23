#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR"

echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

if [[ -n "${CIRCLE_BRANCH+x}" ]] && [[ "$CIRCLE_BRANCH" == 'test' ]]; then
    docker push "${DOCKERHUB_IMAGE}:test-stable"
    docker push "${DOCKERHUB_IMAGE}:test-edge"
else
    docker rmi "${DOCKERHUB_IMAGE}:test-stable" || true
    docker rmi "${DOCKERHUB_IMAGE}:test-edge" || true
    docker push --all-tags "$DOCKERHUB_IMAGE"
fi
