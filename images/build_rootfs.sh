#!/usr/bin/env bash

## build_rootfs.sh will build an ext4 filesystem image from a docker container.
## The image should contain overlay-init which is lifted from the AWS
## firecracker-containerd repo. It creates a tmpfs overlay filesystem at boot
## so that the rootfs image remains untouched.

set -o pipefail
set -o nounset
set -o errexit

id="$(uuidgen | tr A-Z a-z | head -c 16)"

# build 
docker build -t hhtpcd/ubuntu-microvm:${id} -f images/ubuntu/Dockerfile images/
CONTAINER_ID=$(docker run -td hhtpcd/ubuntu-microvm:${id} /bin/bash)
MOUNTDIR=$(mktemp -d)
IMAGE=ubuntu-microvm.ext4
qemu-img create -f raw $IMAGE 800M
mkfs.ext4 $IMAGE
sudo mount $IMAGE $MOUNTDIR
sudo docker cp $CONTAINER_ID:/ $MOUNTDIR
cd images/files/ && sudo tar cf - . | (cd $MOUNTDIR && sudo tar xvf -)
sudo mkdir -p $MOUNTDIR/rom $MOUNTDIR/overlay

# Set user permissions
sudo find $MOUNTDIR/ -type f -user $(id -u) -exec sudo chown root:root {} \;
sudo find $MOUNTDIR/ -type d -user $(id -u) -exec sudo chown root:root {} \;

# cleanup
sudo umount $MOUNTDIR
rm -rf $MOUNTDIR
docker rm -f $CONTAINER_ID

echo ">> done"