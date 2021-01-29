#!/bin/bash

# Install MetalLB on the cluster
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f manifests/metallb_configmap.yaml

# Install linkerd on the cluster
linkerd install | kubectl apply -f -
linkerd check

# Install ingress-nginx on the cluster
# NOTE: manifests/ingress-nginx_deploy.yaml is https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.43.0/deploy/static/provider/baremetal/deploy.yaml
# with ingress-nginx-controller's type changed from NodePort to LoadBalancer.
kubectl apply -f manifests/ingress-nginx_deploy.yaml

# Wait for ingress-nginx is up before continuing
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx
# Seems to need a little extra wait time
sleep 5

# Install the ingress for the linkerd dashbaord on the cluster
kubectl apply -f manifests/linkerd_dashboard_ingress.yaml
