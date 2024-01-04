# Debian DJGPP image

## What is this?

This builds and publishes a Docker container image that can be used to cross-compile DOS programs in a CI/CD pipeline,
such as GitHub Actions Workflows.

## How to build locally

```shell
docker build . -t djgpp-dev-container-v1
```

## Other toolchains

There is also an Open Watcom v2 variant: https://github.com/volkertb/debian-open-watcom
