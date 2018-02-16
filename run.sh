#!/bin/sh

set -e -x 

if [ -z ${PEER+x} ] ; then
	echo 'No peer set. Please provide peer as environment variable `PEER`.'
	exit 1
fi

#peer=${PEER}
peer=$(nslkp "$PEER")
if [ "$?" -ne "0" ]; then
	echo "No such host or invalid IP address. Please provide valid hostname or IP address as environment variable `PEER`.'"
	exit 1
fi

vxlanid=${VXLANID:-100}
dev=${DEV:-$(ip r | grep default | cut  -d' ' -f 5)}
ifname=${IFNAME:-vx${vxlanid}}
bridge=${BRIDGE_IFNAME:-br0}

_lookupip() {
    set +e
    ipcalc -ns $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        set -e
        echo $1
    else
        lookup=`nslookup "$1" 2> /dev/null`
        if [ $? -ne 0 ]; then
            return 2
        fi
        set -e
        echo "$lookup" | grep "Address 1" | cut -f 3 -d " "
    fi
    return 0
}

_set_static_routes() {
    if [ -n "$STATIC_ROUTES" ]; then
        # add routes through the VTI interface
        IFS=","
        if [ ! -z ${BRIDGE+x} ] ; then
            interface=${bridge}
        else
            interface=${ifname}
        fi
        for route in ${STATIC_ROUTES}; do
            # subshell to reset IFS - otherwise ${route} is not split
            # by words
            ( unset IFS; ip route add ${route} dev ${interface} ) || true
        done
    fi 
}

echo "peer is ${peer}"
set +e
peerip=`_lookupip ${peer}`
if [ $? -eq 2 ]; then
  echo "FQDN could not be looked up"   
  exit 1
fi
set -e
echo "IP of peer is ${peerip}"

ip link delete $ifname 2>/dev/null || true
ip link add name $ifname type vxlan id ${vxlanid} dev ${dev} remote ${peerip} dstport 4789
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

_set_static_routes

ip route

echo "Going to infinite sleep ..."
while true; do sleep 1d; done
