# Me, Ahmad and other windows users Ubuntu 24.04 version. This will help save the problem for the
# people that have different OS and doesn't support the same commands. This will help them to run the same commands in a docker container  or more specifically a linux container environment without any issues.
# https://docs.docker.com/build/building/best-practices
FROM ubuntu:24.04
# This will run a command that will update the package list and install the necessary packages for cross-compiling and running ARM binaries. The `--no-install-recommends` option is used to avoid installing unnecessary packages, which helps keep the image size smaller. This will help with installing ubuntu onto Mac users and allowing for a centralized environment for all users to use the same commands without any issues. This will help with the problem of different OS and different commands that are not supported on other OS.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    qemu-user \
    make \  
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace


CMD ["bash"]