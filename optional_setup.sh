#!/bin/bash

# Install linkerd's emojivoto demo app with linkerd injected
linkerd inject https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
kubectl -n emojivoto rollout status deploy/web

# Propagate context and emit spans for jaeger tracing
kubectl -n emojivoto set env --all deploy OC_AGENT_HOST=collector.linkerd-jaeger:55678

# Install the emojivoto LoadBalancer on the cluster
kubectl apply -f manifests/emojivoto_lb.yaml

# Install the kube-verify app with linkerd injected on the cluster
kubectl apply -f manifests/kube-verify.yaml
kubectl -n kube-verify rollout status deploy/kube-verify
kubectl apply -f manifests/kube-verify_lb.yaml
