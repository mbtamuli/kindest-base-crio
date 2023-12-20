# syntax=docker/dockerfile:1
ARG KINDEST_IMAGE=kindest/node
ARG KINDEST_VERSION=v1.25.11@sha256:227fa11ce74ea76a0474eeefb84cb75d8dad1b08638371ecf0e86259b35be0c8
ARG CRIO_VERSION="v1.25.2"

FROM --platform=$BUILDPLATFORM ${KINDEST_IMAGE}:${KINDEST_VERSION}

RUN DEBIAN_FRONTEND=noninteractive clean-install \
        make

#RUN DEBIAN_FRONTEND=noninteractive clean-install \
#        containers-common \
#        cri-o-runc \
#        gcc \
#        git \
#        go-md2man \
#        libassuan-dev \
#        libbtrfs-dev \
#        libc6-dev \
#        libdevmapper-dev \
#        libglib2.0-dev \
#        libgpg-error-dev \
#        libgpgme-dev \
#        libseccomp-dev \
#        libselinux1-dev \
#        libsystemd-dev \
#        libudev-dev \
#        make \
#        pkg-config \
#        software-properties-common

ARG BUILDARCH
ARG CRIO_VERSION
ARG CRIO_TARBALL="cri-o.${BUILDARCH}.${CRIO_VERSION}.tar.gz"
ARG CRIO_URL="https://github.com/cri-o/cri-o/releases/download/${CRIO_VERSION}/${CRIO_TARBALL}"


RUN echo "Installing cri-o ..." \
    && curl -sSL --retry 5 --output /tmp/crio.${BUILDARCH}.tgz "${CRIO_URL}" \
    && tar -C /tmp -xzvf /tmp/crio.${BUILDARCH}.tgz \
    && (cd /tmp/cri-o && make install)\
    && rm -rf /tmp/cri-o /tmp/crio.${BUILDARCH}.tgz
