# syntax=docker/dockerfile:1

# SPDX-License-Identifier: Apache-2.0

ARG DJGPP_INSTALLATION_DIR=/opt/djgpp

FROM debian:13.3-slim AS base

FROM base AS download-and-test-djgpp

ARG DJGPP_INSTALLATION_DIR
ARG DJGPP_RELEASE_VERSION=v3.4
ARG DJGPP_TARBALL_NAME=djgpp-linux64-gcc1220.tar.bz2
ARG DJGPP_TARBALL_SHA256=8464f17017d6ab1b2bb2df4ed82357b5bf692e6e2b7fee37e315638f3d505f00

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt -y update && apt -y install wget lbzip2 make file

# Download, verify and unpack the prebuilt DJGPP binaries for Linux
RUN --mount=type=cache,target=/Downloads \
    echo "${DJGPP_TARBALL_SHA256}  /Downloads/${DJGPP_TARBALL_NAME}" | sha256sum -c - \
    || (wget -O /Downloads/${DJGPP_TARBALL_NAME} \
             https://github.com/andrewwutw/build-djgpp/releases/download/${DJGPP_RELEASE_VERSION}/${DJGPP_TARBALL_NAME} \
        && echo "${DJGPP_TARBALL_SHA256}  /Downloads/${DJGPP_TARBALL_NAME}" | sha256sum -c - )

RUN --mount=type=cache,target=/Downloads \
    tar -xf /Downloads/${DJGPP_TARBALL_NAME} -C /opt

# Make DJGPP available in environment, as instructed at https://github.com/andrewwutw/build-djgpp#using-djgpp-compiler
ENV PATH=${DJGPP_INSTALLATION_DIR}/i586-pc-msdosdjgpp/bin/:$PATH
ENV GCC_EXEC_PREFIX=${DJGPP_INSTALLATION_DIR}/lib/gcc/

# Test compilation with a Hello World source file and a corresponding Makefile
ADD hello_world.c /tmp
ADD hello_world_makefile /tmp
RUN make -C /tmp -f hello_world_makefile

# Verify that the compiled binary is actually a DOS executable
RUN file /tmp/hello.exe | grep "MS-DOS"

FROM base

ARG DJGPP_INSTALLATION_DIR

COPY --from=download-and-test-djgpp ${DJGPP_INSTALLATION_DIR} ${DJGPP_INSTALLATION_DIR}

# Make DJGPP available in environment, as instructed at https://github.com/andrewwutw/build-djgpp#using-djgpp-compiler
ENV PATH=${DJGPP_INSTALLATION_DIR}/i586-pc-msdosdjgpp/bin/:$PATH
ENV GCC_EXEC_PREFIX=${DJGPP_INSTALLATION_DIR}/lib/gcc/

# Most projects that need to be built with DJGPP will likely also need GNU Make, so let's include it in this image.
# `ps` (procps) is required when using this image for a dev container
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt -y update \
    && apt -y install make procps \
    && apt -y autoremove \
    && apt -y clean \
    && rm -rf /var/lib/apt/lists/*
