FROM debian:12.2-slim

ARG DJGPP_RELEASE_VERSION=v3.4
ARG DJGPP_TARBALL_NAME=djgpp-linux64-gcc1220.tar.bz2
ARG DJGPP_TARBALL_SHA256=8464f17017d6ab1b2bb2df4ed82357b5bf692e6e2b7fee37e315638f3d505f00

# Download, verify and unpack the prebuilt DJGPP binaries for Linux
RUN apt -y update
RUN apt -y install wget
RUN wget -P /tmp https://github.com/andrewwutw/build-djgpp/releases/download/${DJGPP_RELEASE_VERSION}/${DJGPP_TARBALL_NAME}
RUN echo "${DJGPP_TARBALL_SHA256}  /tmp/${DJGPP_TARBALL_NAME}" | sha256sum --check
RUN apt -y install lbzip2
RUN tar -xf /tmp/${DJGPP_TARBALL_NAME} -C /opt
RUN rm /tmp/${DJGPP_TARBALL_NAME}
RUN apt -y remove lbzip2

# Make DJGPP available in environment, as instructed at https://github.com/andrewwutw/build-djgpp#using-djgpp-compiler
ENV PATH=/opt/djgpp/i586-pc-msdosdjgpp/bin/:$PATH
ENV GCC_EXEC_PREFIX=/opt/djgpp/lib/gcc/

# Most projects that need to be built with DJGPP will likely also need GNU Make, so let's include it in this image.
RUN apt -y install make

# Test compilation with a Hello World source file and a corresponding Makefile
ADD hello_world.c /tmp
ADD hello_world_makefile /tmp
RUN make -C /tmp -f hello_world_makefile

# Verify that the compiled binary is actually a DOS executable
RUN apt -y install file
RUN file /tmp/hello.exe | grep "MS-DOS"
RUN apt -y remove file
RUN make -C /tmp -f hello_world_makefile clean
RUN rm /tmp/hello_world.c
RUN rm /tmp/hello_world_makefile

# `ps` is required when using this image for a dev container
RUN apt -y install procps
