#! /bin/bash
# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.

set -e
set -x
export DEBIAN_FRONTEND=noninteractive

env

# Hosts arrays computation
. /etc/bootstrap/env.sh

IFS=' ' read -r -a CEPHNODES <<< "${CEPH_NODES}"
NET_IP="$(ip route get 8.8.8.8| head --lines 1 | sed -r -e 's/.+src ([^ ]+).*$/\1/')"
NET_MASK="255.255.240.0"
CIDR=${VPC_CIDR}

. scripts/properties.sh
. scripts/functions.sh

SCRIPT_PATH="${1:-/home/ubuntu/scripts}"

HOSTNAME=$(get_property HOSTNAME)
RACK=$(get_property RACK)
UNIT=$(get_property UNIT)

INTERFACE="eth0"

CEPH_MON_ID=$(get_property CEPH_MON_ID)
CLUSTER=$(get_property CLUSTER)
FSID=$(get_property FSID)
PGNUM=$(get_property PGNUM)
NBMONS=$(get_property NBMONS)

function main(){

  echo ">>> Updating APT sources"
  call apt.sh

  echo ">>> Updating Hostname and /etc/hosts"
  call host.sh


  echo ">>> Installing Ceph client"
  call ceph.sh

  call ceph-mon.sh

  call ceph-osd.sh
}

main "$@"