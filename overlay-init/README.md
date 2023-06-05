# overlay-init

This is a quick and dirty rust rewrite of the 
[overlay-init](https://github.com/firecracker-microvm/firecracker-containerd/blob/3fae0bdd0f592581a2e0519fd6c307b8549569f8/tools/image-builder/files_debootstrap/sbin/overlay-init) script from the 
[firecracker-containerd](https://github.com/firecracker-microvm/firecracker-containerd)
project.

Creates an overlay filesystem for a container rootfs so all writes are on the
overlay instead of the rootfs. This allows the rootfs to be read-only.
