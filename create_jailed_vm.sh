# I'm not sure how well this works, or if it does at all right now.

set -x

id="$(uuidgen | tr A-Z a-z)"
ROOTFS="$HOME/kernel/ubuntu-18.04.ext4"
KERNEL="$HOME/kernel/build/kernel/linux-5.10/vmlinux"

# Clean up
# rm -rf /srv/vm/jailer/firecracker/$id/root
# ip link delete tap0
# ip netns del $id

# create the network namespace
ip netns add $id
jailer_uid=$(id -u jailer)
jailer_gid=$(getent group jailer | awk -F':' '{print $3}')
CNI_ARGS="IgnoreUnknown=1;TC_REDIRECT_TAP_UID=${jailer_uid};TC_REDIRECT_TAP_GID=${jailer_gid};TC_REDIRECT_TAP_NAME=tap1" CNI_PATH="/opt/cni/bin" NETCONFPATH="/etc/cni/net.d/" cnitool add firecracker "/var/run/netns/${id}" | tee /srv/vm/networks/${id}.json
netcfg="/srv/vm/networks/${id}.json"

vm_ip=$(jq -r '.ips[0].address | rtrimstr("/24")' < "${netcfg}")
guest_mac=$(jq -r '.interfaces[] | select(.name == "eth0").mac' < "${netcfg}")
hostname=$(echo "$id" | tr -d '-' | head -c 16)
gateway=$(jq -r '.ips[0].gateway' < "${netcfg}")
mask="255.255.255.0"

CONFIG_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on ip=${vm_ip}::${gateway}:${mask}:${hostname}:eth0:off"

jq "(.\"boot-source\".boot_args) |= \"$CONFIG_BOOT_ARGS\"
        | (.\"network-interfaces\"[0].guest_mac) |= \"$guest_mac\"
          " < "vmconfig.json" | tee "${id}_config.json"

# set up files for the chroot
mkdir -p "/srv/vm/jailer/firecracker/$id/root"
chown jailer:jailer "/srv/vm/jailer/firecracker/$id/root"
cp "$ROOTFS" /srv/vm/jailer/firecracker/$id/root/rootfs.ext4
cp "$KERNEL" /srv/vm/jailer/firecracker/$id/root/kernel.bin
cp "${id}_config.json" /srv/vm/jailer/firecracker/$id/root/config.json
touch /srv/vm/jailer/firecracker/$id/root/out.log

sudo chown -R jailer:jailer /srv/vm/jailer/firecracker/$id/root

tree -pug /srv/vm/jailer/firecracker/$id/root

# Start the jailer
jailer \
    --id $id \
    --daemonize \
    --exec-file "$HOME/bin/firecracker" \
    --uid $(id -u jailer) \
    --gid $(getent group jailer | awk -F':' '{print $3}') \
    --chroot-base-dir "/srv/vm/jailer" \
    --netns "/var/run/netns/$id" \
    --new-pid-ns \
    -- \
    --config-file "config.json" --log-path out.log --level debug

# lol
sleep 1

ps aux | grep firecracker

echo ">> $ip"