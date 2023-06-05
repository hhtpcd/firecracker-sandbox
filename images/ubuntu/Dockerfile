FROM ubuntu:22.04

# udev is needed for booting a "real" VM, setting up the ttyS0 console properly
# kmod is needed for modprobing modules
# systemd is needed for running as PID 1 as /sbin/init
# Also, other utilities are installed
RUN apt-get update && apt-get install -y \
      curl \
      dbus \
      kmod \
      haveged \
      iproute2 \
      iputils-ping \
      net-tools \
      openssh-server \
      procps \
      rng-tools \
      sudo \
      systemd \
      udev \
      vim-tiny \
      wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the following files, but unset them
RUN echo "" > /etc/machine-id && echo "" > /var/lib/dbus/machine-id

# This container image doesn't have locales installed. Disable forwarding the
# user locale env variables or we get warnings such as:
#  bash: warning: setlocale: LC_ALL: cannot change locale
RUN sed -i -e 's/^AcceptEnv LANG LC_\*$/#AcceptEnv LANG LC_*/' /etc/ssh/sshd_config

RUN mkdir -m 0700 -p /root/.ssh

# Set the root password to root when logging in through the VM's ttyS0 console
RUN echo "root:root" | chpasswd