# syntax=docker/dockerfile:1
ARG KINDEST_IMAGE=kindest/node
ARG KINDEST_VERSION=v1.25.11@sha256:227fa11ce74ea76a0474eeefb84cb75d8dad1b08638371ecf0e86259b35be0c8
ARG CRIO_VERSION="v1.25.2"
ARG OS="Debian_11"

FROM --platform=$BUILDPLATFORM ${KINDEST_IMAGE}:${KINDEST_VERSION}
ARG OS

RUN DEBIAN_FRONTEND=noninteractive clean-install \
        file \
        make

ARG BUILDARCH
ARG CRIO_VERSION
ARG CRIO_TARBALL="cri-o.${BUILDARCH}.${CRIO_VERSION}.tar.gz"
ARG CRIO_URL="https://github.com/cri-o/cri-o/releases/download/${CRIO_VERSION}/${CRIO_TARBALL}"

RUN echo "Installing cri-o ..." \
    && curl -sSL --retry 5 --output /root/crio.${BUILDARCH}.tgz "${CRIO_URL}" \
    && tar -C /root -xzvf /root/crio.${BUILDARCH}.tgz \
    && (cd /root/cri-o && make all)\
    && rm -rf /root/cri-o /root/crio.${BUILDARCH}.tgz

RUN echo "list files in /usr/local/bin/" \
    && ls -al /usr/local/bin/ \
    && file /usr/local/bin/ctr


COPY --chmod=0755 files/usr/local/bin/* /usr/local/bin/
# all configs are 0644 (rw- r-- r--)
COPY --chmod=0644 files/etc/* /etc/
# Keep containerd configuration to support kind build
COPY --chmod=0644 files/etc/cni/net.d/* /etc/cni/net.d/
COPY --chmod=0644 files/etc/crio/* /etc/crio/
COPY --chmod=0644 files/etc/default/* /etc/default/
COPY --chmod=0644 files/etc/sysctl.d/* /etc/sysctl.d/
COPY --chmod=0644 files/etc/systemd/system/* /etc/systemd/system/
COPY --chmod=0644 files/etc/systemd/system/kubelet.service.d/* /etc/systemd/system/kubelet.service.d/
COPY --chmod=0644 files/var/lib/kubelet/* /var/lib/kubelet/

RUN echo "list files in /usr/local/bin/" \
    && ls -al /usr/local/bin/ \
    && file /usr/local/bin/ctr

RUN echo "Setup cri-o" \
    && printf "[crio.runtime]\ncgroup_manager=\"cgroupfs\"\nconmon_cgroup=\"pod\"\n" > /etc/crio.conf \
    && cat /etc/crio.conf && echo \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
    && cat /etc/crictl.yaml && echo \
    && systemctl disable containerd \
    && ln -s /etc/contrib/crio.service /etc/systemd/system/crio.service \
    && ln -s /etc/systemd/system/crio.service /etc/systemd/system/multi-user.target.wants/crio.service
