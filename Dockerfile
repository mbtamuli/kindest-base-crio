ARG IMAGE=kindest/node
ARG VERSION=1.25
ARG MINOR=2
ARG OS=xUbuntu_22.04

FROM ${IMAGE}:v${VERSION}.${MINOR}

ARG VERSION
ARG OS

RUN echo "Installing Packages ..." \
    && DEBIAN_FRONTEND=noninteractive clean-install \
    tcpdump \
    vim \
    gnupg \
    tzdata \
 && echo "Installing cri-o" \
    && export CONTAINERS_URL="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${OS}/" \
    && echo "deb ${CONTAINERS_URL} /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
    && export CRIO_URL="http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${VERSION}/${OS}/" \
    && echo "deb ${CRIO_URL} /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:${VERSION}.list \
    && curl -L ${CONTAINERS_URL}Release.key | apt-key add - || true \
    && curl -L ${CRIO_URL}Release.key | apt-key add - || true \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --option=Dpkg::Options::=--force-confdef install -y cri-o cri-o-runc \
    && ln -s /usr/libexec/podman/conmon /usr/local/bin/conmon \
    && sed -i 's/^pause_image =.*/pause_image = \"registry.k8s.io\/pause:3.7\"/' /etc/crio/crio.conf \
    && sed -i 's/.*storage_driver.*/storage_driver = \"vfs\"/' /etc/crio/crio.conf \
    && sed -i 's/^cgroup_manager =.*/cgroup_manager = \"cgroupfs\"/' /etc/crio/crio.conf \
    && sed -i 's/^cgroup_manager =.*/a conmon_cgroup = \"pod\"/' /etc/crio/crio.conf \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
 && systemctl disable containerd \
 && systemctl enable crio
