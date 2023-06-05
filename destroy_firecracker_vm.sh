set -x

CHROOT_BASE="/srv/vm/jailer"

destroy() {
    local uid gid

    uid=$(id -u jailer)
    gid=$(getent group jailer | awk -F':' '{print $3}')

    curl \
         --unix-socket \
         "${CHROOT_BASE}/firecracker/${1}/root/run/firecracker.socket" \
         -H "accept: application/json" \
         -H "Content-Type: application/json" \
         -X PUT "http://localhost/actions" \
         -d "{ \"action_type\": \"SendCtrlAltDel\" }"

    curl \
         --unix-socket \
         "/run/${1}_firecracker.socket" \
         -H "accept: application/json" \
         -H "Content-Type: application/json" \
         -X PUT "http://localhost/actions" \
         -d "{ \"action_type\": \"SendCtrlAltDel\" }"

    # lol
    sleep 3

    rm -rf "${CHROOT_BASE}/firecracker/${1}"
    CNI_ARGS="IgnoreUnknown=1;TC_REDIRECT_TAP_UID=${uid};TC_REDIRECT_TAP_GID=${gid};TC_REDIRECT_TAP_NAME=tap1" CNI_PATH="/opt/cni/bin" NETCONFPATH="/etc/cni/net.d/" cnitool del firecracker "/var/run/netns/${1}"
    ip netns del $1

    rm -v "/var/run/${1}_firecracker.socket"

    rm -v "${1}_config.json"
}

destroy "$1"
