#!/usr/bin/env bash
# Builds the image and runs it on a LOCAL Kubernetes cluster (kind or Docker Desktop).
# Refuses to touch any other cluster, so it can never deploy to a real EKS cluster by accident.
#
#   scripts/k8s-local.sh            # uses kind if installed, else Docker Desktop's Kubernetes
#   scripts/k8s-local.sh down       # removes the app (and the kind cluster)
set -euo pipefail

cd "$(dirname "$0")/.."
IMAGE=pocket-orrery:local
CLUSTER=pocket-orrery

if command -v kind >/dev/null 2>&1; then
  CONTEXT="kind-$CLUSTER"
else
  CONTEXT="docker-desktop"
fi
k() { kubectl --context "$CONTEXT" "$@"; }

case "$CONTEXT" in
  kind-* | docker-desktop) ;;
  *) echo "Refusing to use context '$CONTEXT': only local clusters are allowed." >&2; exit 1 ;;
esac

if [ "${1:-up}" = "down" ]; then
  k delete namespace pocket-orrery --ignore-not-found
  if [ "$CONTEXT" = "kind-$CLUSTER" ]; then kind delete cluster --name "$CLUSTER"; fi
  exit 0
fi

if [ "$CONTEXT" = "kind-$CLUSTER" ] && ! kind get clusters | grep -qx "$CLUSTER"; then
  kind create cluster --name "$CLUSTER" --config k8s/kind/cluster.yaml
fi
if ! kubectl config get-contexts -o name | grep -qx "$CONTEXT"; then
  echo "No '$CONTEXT' context. Install kind, or turn on Kubernetes in Docker Desktop settings." >&2
  exit 1
fi

docker build -f docker/Dockerfile -t "$IMAGE" .
if [ "$CONTEXT" = "kind-$CLUSTER" ]; then kind load docker-image "$IMAGE" --name "$CLUSTER"; fi

k apply -k k8s
k -n pocket-orrery rollout restart deployment/pocket-orrery
k -n pocket-orrery rollout status deployment/pocket-orrery --timeout=120s
k -n pocket-orrery get pods -o wide
echo "Open http://localhost:30080"
