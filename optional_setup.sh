#!/bin/bash

# Install linkerd's emojivoto demo app with linkerd injected
curl -sL https://run.linkerd.io/emojivoto.yml | linkerd inject - | kubectl apply -f -

# Add opencensus collector to emojivoto
kubectl -n emojivoto patch -f https://run.linkerd.io/emojivoto.yml -p "$(cat manifests/emojivoto_patch.yaml)"

# Wait for patch to be applied
kubectl -n emojivoto rollout status deploy/web

# Propagate context and emit spans for jaeger tracing
kubectl -n emojivoto set env --all deploy OC_AGENT_HOST=linkerd-collector.linkerd:55678

# Install the emojivoto LoadBalancer on the cluster
kubectl apply -f manifests/emojivoto_lb.yaml

# Install the kube-verify app with linkerd injected on the cluster
kubectl create namespace kube-verify
kubectl apply -f manifests/kube-verify.yaml
kubectl apply -f manifests/kube-verify_lb.yaml
