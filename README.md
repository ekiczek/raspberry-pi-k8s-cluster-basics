# raspberry-pi-k8s-cluster-basics

This repo installs useful basic add-ons for a Raspberry Pi cluster with Kubernetes (or any Kubernetes cluster for that matter). It builds upon the raspberry-pi-k8s repo and is intended to be run after the cluster is up and running.

The basic setup script installs [linkerd](https://linkerd.io), [Jaeger](https://www.jaegertracing.io), [Prometheus](https://prometheus.io), [MetalLB](https://metallb.universe.tf) and [ingress-nginx](https://kubernetes.github.io/ingress-nginx/).
* **Linkerd** provides a service mesh and is installed with an easily-accessible dashboard (which you would _not_ expose in a production environment!).
* **Jaeger** is an end-to-end distributed tracing system that integrates well with Linkerd.
* **Prometheus** is an open-source systems monitoring and alerting toolkit.
* **MetalLB** provides a "bare metal" load balancing capability so that installed apps can have a publicly available IP address.
* **Ingress-nginx** provides a compatible frontend for the linkerd dashboard.

The optional setup script installs two additional apps to demonstrate the capabilities of the tools installed in the basic setup script.

# Purpose
I wanted to learn more about how Kubernetes works _after_ you set up the basics, so I created this automation to easily re-build a cluster whenever I wanted to start over.

# Prerequisites
The Instructions below assume the following:
1. You have a working Kubernetes cluster based on the recipe in the [raspberry-pi-k8s repo](https://github.com/ekiczek/raspberry-pi-k8s), and you have enabled "promiscuous mode" by following the instructions in that repo. Enabling promiscuous mode is required for the proper operation of MetalLB.
1. You have `kubectl` installed. For example, you can install it on a Mac using HomeBrew with `brew install kubectl`.
1. You have `linkerd` installed on the same computer where `kubectl` is installed. See Step 1 at https://linkerd.io/2/getting-started/index.html for simple instructions to install linkerd. For example, you can install it on a Mac using HomeBrew with `brew install linkerd`.
1. You have installed the cluster configuration file from the master to the same computer where `kubectl` is installed. You can get the file by running scp ubuntu@<MASTER_IP>:/home/ubuntu/.kube/config ~/.kube/. _NOTE: You may need to SSH in and change the default password before running this command._
1. You have cloned this repo to the same computer where `kubectl` is installed.
1. You have the ability to reserve a block of IP addresses for the exclusive use of MetalLB. For example, my home router allows me to specify a range of IPs which it can hand out to connected devices via DHCP. This means I can limit the range of IPs on the subnet, and then effective reserve the remaining IPs for MetalLB.
1. You have created an `occollector` image for the ARM64 architecture and it is available in a Docker repository like DockerHub. See instructions below for details on how to create this image.
1. You have the ability to add a manual DNS entry to your system for Prometheus access. See instructions below for more details.

# A note about MetalLB and promiscuous mode
As noted in the Prerequisites above, all nodes need to be in promiscuous mode before installing MetalLB. See https://stackoverflow.com/questions/60796696/loadbalancer-using-metallb-on-bare-metal-rpi-cluster-not-working-after-installat for more on this. Omitting this step, I found that MetalLB initially worked but eventually stopped responding, usually in about 20 minutes.

Promiscuous mode can be enabled by setting up the cluster using the [raspberry-pi-k8s repo](https://github.com/ekiczek/raspberry-pi-k8s), but can also be done manually by SSHing into all nodes and running:
1. `sudo ip link set wlan0 promisc on`
1. Then `sudo crontab -e` and add this to the end of the cron file: `@reboot root sudo ip link set wlan0 promisc on`

# Creating the `occollector` image
As noted in the Prerequisites above, you need an `occollector` image for the ARM64 architecture and it needs to be available in a Docker repository like DockerHub. You can create this image on one of the Raspberry Pis in your cluster and then upload the image to your Docker repository. Here's how:

1. SSH into one of the Raspberry Pis in your cluster.
1. `git clone https://github.com/census-instrumentation/opencensus-service`.
1. `cd opencensus-service`.
1. Run the following commands to make the image:
   ```
   sudo apt install make
   sudo apt install golang-go
   make docker-collector
   ```
1. This creates an image named `occollector`. Re-tag it by running: `sudo docker tag occollector <YOUR_REPO>/linkerd-collector`, where `YOUR_REPO` is the name of your DockerHub repo.
1. Assuming you're using DockerHub, login to DockerHub and push the image by running:
   ```
   sudo docker login
   sudo docker push <YOUR_REPO>/linkerd-collector
   ```

# Instructions
1. From this repo, copy `manifests/metallb_configmap.yaml.orig` to `manifests/metallb_configmap.yaml`. Change `<YOUR_IP_POOL>` to the value which MetalLB will use to distribute IP addresses, e.g., `192.168.1.128/25`. See https://metallb.universe.tf/configuration/ for more information.
1. From this repo, copy `manifests/linkerd_config.yaml.orig` to `manifests/linkerd_config.yaml`. Change `<YOUR_REPO>` to the value of your DockerHub repo so that your `linkerd-collector` image is used during the linkerd and Jaeger installation. See instructions above about the `occollector` for more details.
1. From this repo, copy `manifests/linkerd_prometheus_ingress.yaml.orig` to `manifests/linkerd_prometheus_ingress.yaml`. Change `<YOUR_PROMETHEUS_HOST>` to a fake domain name which will be used to browse to the Prometheus interface, e.g., `myprometheus.com`.
1. Run the `setup.sh` script. After a few minutes, linkerd, jaeger, Prometheus. MetalLB and ingress-nginx will be installed, and the linkerd dashboard should be available at one of the addresses in the MetalLB IP pool. In order to determine the IP address of the linkerd dashboard, run `kubectl get service ingress-nginx-controller -n ingress-nginx` and note the external IP. In a web browser, browse to that IP and enter `admin/admin` as the username and password.
1. In order to access Prometheus, add a manual DNS entry to your local hosts file for the domain you specified for Prometheus. For example, on a Mac, edit `/private/etc/hosts` and add a line like:
   ```
   <INGRESS_NGINX_CONTROLLER_IP_FROM_ABOVE>   <YOUR_PROMETHEUS_HOST>
   ```
   where `<INGRESS_NGINX_CONTROLLER_IP_FROM_ABOVE>` is the IP obtained in the previous step and `<YOUR_PROMETHEUS_HOST>` is the Prometheus host you specified in the `manifests/linkerd_prometheus_ingress.yaml` file. In a web browser, browse to that hostname and enter `admin/admin` as the username and password.

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
