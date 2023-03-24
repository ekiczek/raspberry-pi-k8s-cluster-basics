FROM mcr.microsoft.com/devcontainers/base:jammy
# Install the xz-utils package
RUN apt-get update && apt-get install -y xz-utils

RUN curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
ENV PATH=$PATH:/root/.linkerd2/bin

RUN mkdir /root/.kube