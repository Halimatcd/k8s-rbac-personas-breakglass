#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"; cd "$ROOT"
kind delete cluster --name "$CLUSTER"; rm -rf kubeconfigs
