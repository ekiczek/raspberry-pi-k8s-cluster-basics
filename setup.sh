#!/bin/bash

# Install MetalLB on the cluster
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml

# Wait for metallb controller is up before continuing
kubectl rollout status deployment/controller -n metallb-system
# Seems to need a little extra wait time
sleep 5

kubectl apply -f manifests/metallb_resources.yaml

# Install linkerd on the cluster
linkerd install --set proxyInit.runAsRoot=true --crds | kubectl apply -f -
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
linkerd check

# Install Linkerd dashboard
linkerd viz install --set proxyInit.runAsRoot=true | kubectl apply -f -
linkerd viz check

# Install Linkerd Jaeger extension
linkerd jaeger install | kubectl apply -f -
linkerd jaeger check

# Install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana -n grafana --create-namespace grafana/grafana -f https://raw.githubusercontent.com/linkerd/linkerd2/main/grafana/values.yaml
kubectl -n grafana rollout status deploy/grafana

# Enable Jaeger and Grafana access from Linkerd dashboard
linkerd viz install --set jaegerUrl=jaeger.linkerd-jaeger:16686 --set grafana.url=grafana.grafana:3000 | kubectl apply -f -

# Install ingress-nginx on the cluster
curl -sSL "https://github.com/kubernetes/ingress-nginx/blob/controller-v1.6.4/deploy/static/provider/baremetal/deploy.yaml?raw=true" | sed "s/NodePort/LoadBalancer/g" | kubectl apply -f -

# Wait for ingress-nginx is up before continuing
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx
# Seems to need a little extra wait time
sleep 5

# Install the ingress for the linkerd dashboard on the cluster
kubectl apply -f manifests/linkerd_dashboard_ingress.yaml

# Install the ingress for Prometheus on the cluster
kubectl apply -f manifests/linkerd_prometheus_ingress.yaml
