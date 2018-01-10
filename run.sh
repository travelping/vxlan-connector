#!/bin/sh

set -e -x

if [ -z ${PEER+x} ] ; then
	echo 'No peer set. Please provide peer as environment variable `PEER`.'
	exit 1
fi

peer=${PEER}
vxlanid=${VXLANID:-100}
dev=${DEV:-$(ip r | grep default | cut  -d' ' -f 5)}
ifname=${IFNAME:-vx${vxlanid}}
bridge=${BRIDGE_IFNAME:-br0}

ip link delete $ifname 2>/dev/null || true
ip link add name $ifname type vxlan id ${vxlanid} dev ${dev} remote ${peer} dstport 4789
ip link set $ifname up

# bridge interface
if [ ! -z ${BRIDGE+x} ] ; then
	(ip l set $bridge down ; brctl delbr $bridge 2>/dev/null) || true
	brctl addbr $bridge
	for i in ${BRIDGED_IFACES}; do
		brctl addif $bridge $i
		ip l set $i up
	done
	brctl addif $bridge $ifname

	[ ! -z ${IP_ADDR+x} ] && ip a add ${IP_ADDR} dev ${bridge}

	ip link set $ifname up
	ip l set $bridge up
	brctl show
# vxlan interface
else
	[ ! -z ${IP_ADDR+x} ] && ip a add ${IP_ADDR} dev ${ifname}
fi

ip a

echo "Going to infinite sleep ..."
while true; do sleep 1d; done
