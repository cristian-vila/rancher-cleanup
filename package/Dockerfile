FROM registry.suse.com/bci/bci-base:15.4.27.14.39

ARG KUBERNETES_RELEASE=v1.23.13
WORKDIR /usr/local/bin
RUN set -x \
 && zypper -n install curl \
 && curl -fsSLO https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/amd64/kubectl \
 && chmod +x kubectl

COPY cleanup.sh /cleanup.sh
COPY verify.sh /verify.sh
RUN chmod +x /cleanup.sh /verify.sh
ENTRYPOINT ["/cleanup.sh"]
