.PHONY: rootfs
rootfs:
	@echo "Building rootfs"
	images/build_rootfs.sh

.PHONY: build-kernel
build-kernel:
	@echo "Building kernel"
	images/build_kernel.sh