# Firecracker Sandbox

> [!IMPORTANT] 
> No promises that this will work for you! This works on my machine
> but the concepts and scripts might still be useful.

This repository contains a set of scripts and configurations files to 
run firecracker microVMs, build VM images, and manage the network configuration.

## Requirements

- CNI Plugins installed to `/opt/cni/bin`
- Network configuration files in `/etc/cni/net.d` (Configurable with `NETCONF` env var)
- `firecracker` and `jailer` binaries in $PATH.
- rootfs and kernel
- `jailer` user

## Build a rootfs

We can use docker to build a rootfs from a container image. Some OS images
require changes to include an init system, user and SSH keys.

```sh
CONTAINER_ID=$(docker run -td ubuntu:22.04 /bin/bash)
MOUNTDIR=mnt
IMAGE=ubuntu.ext4
mkfs.ext4 $IMAGE
qemu-img create -f raw $IMAGE 800M
sudo mount $IMAGE $MOUNTDIR
docker cp $CONTAINER_ID:/ $MOUNTDIR
```

Use the `make rootfs` target to build the rootfs from a container image.

## Build a kernel

We can build a kernel image from the kernel repo. This uses the microvm config
from the firecracker repo to build the kernel. It is tuned for microVM use
and has specific configuration for the 5.10 LTS release.

Use the `make build-kernel` target to build the kernel.

### Firecracker Kernel Image

Use the firecracker kernel from the firecracker repo. This is a pre-built image
and is configured for microVM use. You will need to update the `firecracker_vm.json`
configuration to use this kernel image, see the `boot_source.kernel_image_path`
key.

```sh
ARCH=$(uname -m)
wget https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.7/${ARCH}/vmlinux-5.10.204
```

### Manually

Uses `gcc11` to build, this might not be available by default in your system.
It takes a long time to install in Arch because it compiles :sob:

```sh
curl -L https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.181.tar.xz > linux-5.10.181.tar.xz
mkdir linux-5.10.181
tar --skip-old-files --strip-components=1 -xf linux-5.10.181.tar.xz -C linux-5.10.181/
cd linux-5.10.181/
cp /workspaces/build/firecracker/resources/guest_configs/microvm-kernel-x86_64-5.10.config .config
make CC="gcc-11" olddefconfig
make CC="gcc-11" vmlinux -j$(nproc)
```

## Networking

The CNI plugins are able to configure all aspects of the network for our microVMs.
They will create a shared bridge interface, the `iptables` routing and firewall
rules for MASQUERADE and FORWARDING. This is _beyond_ useful.

We use the `cnitool` binary to execute the plugins out of band, where they would
usually be executed by the container runtime.

## Running a microVM

Use the start script to run a microVM. It will create the configuration
and open the VM interactively in your terminal.

```sh
sudo ./start_firecracker_vm.sh
```

## Destroy a microVM

Get the unique ID either from the start-up logs or from the network namespace
list.

```sh
sudo ip netns ls
```

Then use the destroy script to remove the VM and network configuration.

```sh
sudo ./destroy_firecracker_vm.sh <ID>
```

## TODO

- [ ] Fix the destroy script. When the VM kernel has the i8042 module disabled
        it doesn't appear to handle CtrlAltDel correctly.
