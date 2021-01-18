#!/bin/bash

# Install linkerd's emojivoto demo app with linkerd injected
curl -sL https://run.linkerd.io/emojivoto.yml | linkerd inject - | kubectl apply -f -

# Install the emojivoto LoadBalancer on the cluster
kubectl apply -f manifests/emojivoto_lb.yaml

# Install the kube-verify app with linkerd injected on the cluster
kubectl create namespace kube-verify
kubectl apply -f manifests/kube-verify.yaml
kubectl apply -f manifests/kube-verify_lb.yaml
