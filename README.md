# VXLAN Connector

A docker image to create a VXLAN towards a peer.

A container from this image is supposed to be used as VNF and/or sidecar to
interconnect other VNFs or applications.


## Environment Variables

The following environment variables are used to configure the VXLAN connector:

- `PEER`: VXLAN peer IP address, required
- `VXLANID`: VXLAN ID to use, default: `100`
- `IFNAME`: Interface name of the VXLAN device, default `vx${vxlanid}`, e.g. `vx100`.
- `IP_ADDR`: An IP address to be added to the vxlan interface (CIDR notation).
  IF `BRIDGE` is set, the IP address is configured for the bridge interface.
- `BRIDGE`: If set, a bridge is created and the VXLAN device is attached to it.
- `BRIDGE_IFNAME`: Interface name of the bridge, default `br0`
  (e.g. `vx100`)
- `BRIDGED_IFACES`: A space-separated list of interface names to attach to the
  bridge in addition to the vxlan interface.
