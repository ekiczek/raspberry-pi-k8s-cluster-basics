# raspberry-pi-k8s-cluster-basics

This repo installs useful basic add-ons for a Raspberry Pi cluster with Kubernetes (or any Kubernetes cluster for that matter). It builds upon the raspberry-pi-k8s repo and is intended to be run after the cluster is up and running.

The basic setup script installs [linkerd](https://linkerd.io), [Jaeger](https://www.jaegertracing.io), [Prometheus](https://prometheus.io), [Grafana](https://grafana.com/), [MetalLB](https://metallb.universe.tf) and [ingress-nginx](https://kubernetes.github.io/ingress-nginx/).
* **Linkerd** provides a service mesh and is installed with an easily-accessible dashboard (which you would _not_ expose in a production environment!).
* **Jaeger** is an end-to-end distributed tracing system that integrates well with Linkerd.
* **Prometheus** is an open-source systems monitoring and alerting toolkit.
* **Grafana** is an open-source platform for monitoring and observability.
* **MetalLB** provides a "bare metal" load balancing capability so that installed apps can have a publicly available IP address.
* **Ingress-nginx** provides a compatible frontend for the linkerd dashboard.

The optional setup script installs two additional apps to demonstrate the capabilities of the tools installed in the basic setup script.

# Purpose
I wanted to learn more about how Kubernetes works _after_ you set up the basics, so I created this automation to easily re-build a cluster whenever I wanted to start over.

# Prerequisites
The Instructions below assume the following:
1. You have a working Kubernetes cluster based on the recipe in the [raspberry-pi-k8s repo](https://github.com/ekiczek/raspberry-pi-k8s), and you have enabled "promiscuous mode" by following the instructions in that repo. Enabling promiscuous mode is required for the proper operation of MetalLB.
1. You have `kubectl`, `linkerd` and `helm` installed. They are pre-installed in the Visual Studio Code development container defined in this repo.
1. You have installed the cluster configuration file from the master to the same computer where `kubectl` is installed. You can get the file by running scp ubuntu@<MASTER_IP>:/home/ubuntu/.kube/config ~/.kube/. _NOTE: You may need to SSH in and change the default password before running this command._
1. You have cloned this repo to the same computer (or dev container) where `kubectl` is installed.
1. You have the ability to reserve a block of IP addresses on your network for the exclusive use of MetalLB. For example, my home router allows me to specify a range of IPs which it can hand out to connected devices via DHCP. This means I can limit the range of IPs on the subnet, and then effective reserve the remaining IPs for MetalLB.
1. You have the ability to add manual DNS entries to your system (e.g., in `/etc/hosts`) for Linkerd dashboard and Prometheus access. See instructions below for more details.

# A note about MetalLB and promiscuous mode
As noted in the Prerequisites above, all nodes need to be in promiscuous mode before installing MetalLB. See https://stackoverflow.com/questions/60796696/loadbalancer-using-metallb-on-bare-metal-rpi-cluster-not-working-after-installat for more on this. Omitting this step, I found that MetalLB initially worked but eventually stopped responding, usually in about 20 minutes.

Promiscuous mode can be enabled by setting up the cluster using the [raspberry-pi-k8s repo](https://github.com/ekiczek/raspberry-pi-k8s), but can also be done manually by SSHing into all nodes and running:
1. `sudo ip link set wlan0 promisc on`
1. Then `sudo crontab -e` and add this to the end of the cron file: `@reboot root sudo ip link set wlan0 promisc on`

# Instructions
1. From this repo, copy `manifests/metallb_resources.yaml.orig` to `manifests/metallb_resources.yaml`. Change `<YOUR_IP_POOL>` to the value which MetalLB will use to distribute IP addresses, e.g., `192.168.1.128/25`. See https://metallb.universe.tf/configuration/ for more information.
1. From this repo, copy `manifests/linkerd_dashboard_ingress.yaml.orig` to `manifests/linkerd_dashboard_ingress.yaml`. Change `<YOUR_LINKERD_DASHBOARD_HOST>` to a fake domain name which will be used to browse to the Prometheus interface, e.g., `mylinkerd.com`.
1. From this repo, copy `manifests/linkerd_prometheus_ingress.yaml.orig` to `manifests/linkerd_prometheus_ingress.yaml`. Change `<YOUR_PROMETHEUS_HOST>` to a fake domain name which will be used to browse to the Prometheus interface, e.g., `myprometheus.com`.
1. Run the `setup.sh` script. After a few minutes, linkerd, jaeger, Prometheus, Grafana, MetalLB and ingress-nginx will be installed.
1. In order to access the Linkerd dashboard and Prometheus, add manual DNS entries to your local hosts file for the domains you specified for Linkerd and Prometheus. First, run `kubectl get service ingress-nginx-controller -n ingress-nginx` and note the external IP. Now add entries to your local hosts file. For example, on a Mac, edit `/private/etc/hosts` and add a line like:
   ```
   <INGRESS_NGINX_CONTROLLER_IP_FROM_ABOVE>   <YOUR_LINKERD_DASHBOARD_HOST>
   <INGRESS_NGINX_CONTROLLER_IP_FROM_ABOVE>   <YOUR_PROMETHEUS_HOST>
   ```
   where `<INGRESS_NGINX_CONTROLLER_IP_FROM_ABOVE>` is the IP address obtained above. In a web browser, browse to those hostnames and enter `admin/admin` as the username and password in order to access the Linkerd dashboard and Prometheus.

## Optional Post-Installation Steps
1. Run the `optional_setup.sh` script to install the emojivoto and kube-verify apps. These are very basic apps that show how to use MetalLB for load balancing and show how to integrate with linkerd. Jaeger tracing is enabled for the emojivoto app. In order to determine the IP address of the emojivoto app, run `kubectl get service emojivoto -n emojivoto` and note the external IP. In a web browser, browse to that IP. In order to determine the IP address of the kube-verify app, run `kubectl get service kube-verify -n kube-verify` and note the external IP. In a web browser, browse to that IP.

# References
* linkerd: https://linkerd.io
* MetalLB: https://metallb.universe.tf
* ingress-nginx: https://kubernetes.github.io/ingress-nginx/
* raspberry-pi-k8s repo: https://github.com/ekiczek/raspberry-pi-k8s
* https://stackoverflow.com/questions/60796696/loadbalancer-using-metallb-on-bare-metal-rpi-cluster-not-working-after-installat
* https://opensource.com/article/20/7/homelab-metallb
* linkerd dashboard exposure:
  * https://stackoverflow.com/questions/57031505/metallb-with-nginx-ingress-controller-on-minkube-keeps-resetting-external-ip-for
  * https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md#bare-metal
  * https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/baremetal.md
  * https://linkerd.io/2/tasks/exposing-dashboard/
* Jaeger-related links
  * https://linkerd.io/2/tasks/distributed-tracing/
  * https://linkerd.io/2/tasks/enabling-addons/
  * https://linkerd.io/2019/10/07/a-guide-to-distributed-tracing-with-linkerd/
  * https://www.digitalocean.com/community/tutorials/how-to-implement-distributed-tracing-with-jaeger-on-kubernetes
  * https://github.com/jaegertracing/jaeger/pull/2611#issuecomment-756551777
  * https://github.com/querycap/jaeger#querycapjaegertracingall-in-one1210
  * https://github.com/jaegertracing/jaeger/releases
* Prometheus: https://prometheus.io
* Grafana: https://grafana.com/
