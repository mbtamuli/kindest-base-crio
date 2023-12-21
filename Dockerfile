# syntax=docker/dockerfile:1
ARG KINDEST_IMAGE=kindest/node
ARG KINDEST_VERSION=v1.25.11@sha256:227fa11ce74ea76a0474eeefb84cb75d8dad1b08638371ecf0e86259b35be0c8
ARG CRIO_VERSION="v1.25.2"
ARG OS="Debian_11"

FROM --platform=$BUILDPLATFORM ${KINDEST_IMAGE}:${KINDEST_VERSION}
ARG OS

COPY --chmod=0755 files/usr/local/bin/* /usr/local/bin/

RUN DEBIAN_FRONTEND=noninteractive clean-install \
        file \
        make \
        tree

ARG TARGETARCH
ARG CRIO_VERSION
ARG CRIO_TARBALL="cri-o.${TARGETARCH}.${CRIO_VERSION}.tar.gz"
ARG CRIO_URL="https://github.com/cri-o/cri-o/releases/download/${CRIO_VERSION}/${CRIO_TARBALL}"
ARG FUSE_OVERLAYFS_VERSION="1.9"
ARG FUSE_OVERLAYFS_TARBALL="v${FUSE_OVERLAYFS_VERSION}/fuse-overlayfs-${TARGETARCH}"
ARG FUSE_OVERLAYFS_URL="https://github.com/containers/fuse-overlayfs/releases/download/${FUSE_OVERLAYFS_TARBALL}"

RUN echo "list files" \
    && { ls -al /etc/cni/net.d/ || true; } \
    && { ls -al /etc/containers/ || true; } \
    && { ls -al /etc/crictl.yaml || true; } \
    && { ls -al /usr/local/lib/systemd/system/crio.service || true; } \
    && { ls -al /etc/crio/crio.conf.d/ || true; } \
    && { ls -al /usr/local/bin/ || true; }

RUN echo "Installing cri-o ..." \
    && curl -sSL --retry 5 --output /root/crio.${TARGETARCH}.tgz "${CRIO_URL}" \
    && tar -C /root -xzvf /root/crio.${TARGETARCH}.tgz \
    && cd /root/cri-o && make all \
    && rm -rf /root/cri-o /root/crio.${TARGETARCH}.tgz

RUN echo "list files" \
    && { ls -al /etc/cni/net.d/ || true; } \
    && { ls -al /etc/containers/ || true; } \
    && { ls -al /etc/crictl.yaml || true; } \
    && { ls -al /usr/local/lib/systemd/system/crio.service || true; } \
    && { ls -al /etc/crio/crio.conf.d/ || true; } \
    && { ls -al /usr/local/bin/ || true; }

RUN echo "Installing fuse-overlayfs ..." \
    && curl -sSL --retry 5 --output /tmp/fuse-overlayfs.${TARGETARCH} "${FUSE_OVERLAYFS_URL}" \
    && mv -f /tmp/fuse-overlayfs.${TARGETARCH} /usr/local/bin/fuse-overlayfs \
    && chmod +x /usr/local/bin/fuse-overlayfs

RUN echo "list files in /usr/local/bin/" \
    && ls -al /usr/local/bin/ \
    && file /usr/local/bin/ctr

# all configs are 0644 (rw- r-- r--)
COPY --chmod=0644 files/etc/* /etc/

RUN echo "Setup cri-o" \
    && cat /etc/crio.conf && echo \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
    && cat /etc/crictl.yaml && echo

RUN echo "list files in /usr/local/bin/" \
    && ls -al /usr/local/bin/ \
    && file /usr/local/bin/ctr

RUN systemctl disable containerd \
    && systemctl enable crio
