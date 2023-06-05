#!/usr/bin/env bash


id="$(uuidgen | tr A-Z a-z)"

# create the network namespace
ip netns add $id
CNI_ARGS="IgnoreUnknown=1;TC_REDIRECT_TAP_NAME=tap1" CNI_PATH="/opt/cni/bin" NETCONFPATH="$(pwd)/net.d" cnitool add firecracker "/var/run/netns/${id}" | tee /srv/vm/networks/${id}.json
netcfg="/srv/vm/networks/${id}.json"

vm_ip=$(jq -r '.ips[0].address | rtrimstr("/24")' < "${netcfg}")
guest_mac=$(jq -r '.interfaces[] | select(.name == "eth0").mac' < "${netcfg}")
hostname=$(echo "$id" | tr -d '-' | head -c 16)
gateway=$(jq -r '.ips[0].gateway' < "${netcfg}")
mask="255.255.255.0"

qemu-img create -f raw ${id}_overlay.img 1200M
mkfs.ext4 -F ${id}_overlay.img

CONFIG_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on i8042.noaux i8042.nomux i8042.nopnp i8042.nokbd ip=${vm_ip}::${gateway}:${mask}:${hostname}:eth0:off systemd.journald.forward_to_console init=/sbin/overlay-init overlay_root=vdb"

jq "(.\"boot-source\".boot_args) |= \"$CONFIG_BOOT_ARGS\"
        | (.\"network-interfaces\"[0].guest_mac) |= \"$guest_mac\"
        | (.\"drives\"[1].path_on_host) |= \"${id}_overlay.img\"
          " < "firecracker_vm.json" | tee "${id}_config.json"

sudo ip netns exec ${id} firecracker --api-sock /run/${id}_firecracker.socket --config-file ${id}_config.json

sleep 2

ps aux | grep firecracker
