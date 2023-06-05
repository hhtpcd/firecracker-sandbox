# networking

Firecracker VMs require a TAP device as a network interface. The firecracker
docs support creating this manually, and also adding iptables rules, etc. This
becomes time consuming when we want to run multiple VMs, and also when we want to
start something quickly locally, and without a fully fledged orchestrator.

We can use the Container Network Interface (CNI) plugins to manage the TAP device
for us. The CNI and plugins are responsible for inserting a network interface
into the container network namespace and making any necessary changes to the
host network namespace.

- https://www.redhat.com/sysadmin/cni-kubernetes

We can use the CNI plugins to manage a bridge interface, veth pairs, TAP device
and iptables. The `ipam` configuration in the `bridge` plugin allows us to
assign IP addresses from a range to the veth pair interfaces for our Firecracker
VMs.

This plugin also creates the `iptables` rules for masquerading and forwarding
traffic from the host to the bridge.

See [`net.d/`](../net.d) for the CNI configuration files.

The CNI plugins are intended to be used by container runtimes and operate
within a network namespace. This isn't all that bad for us because we can
create a network namespace and launch our VM inside it.

```sh
ip netns add fc-$(uuidgen)
```

We use the `cnitool` binary to execute the plugins out of band against our
configuration files and network namespace.

The final plugin in the chain is the `tc-redirect-tap` plugin. This is authored
by AWS specifically for firecracker. They also use the CNI plugins to manage
networking in their firecracker demo. The plugin takes the veth pair result
output and creates a TAP device. The plugin uses `tc` to redirect and mirror all
traffic from the veth pair.

https://github.com/awslabs/tc-redirect-tap

Lastly we use the `portmap` plugin to map ports from the host to the VM
interfaces. This works in the same way Kubernetes Services or Docker port
forwarding. All with iptables DNAT and SNAT.