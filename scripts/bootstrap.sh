#! /bin/bash
# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.

set -e
set -x
export DEBIAN_FRONTEND=noninteractive

source /etc/bootstrap/env.sh
env

if [[ -z "$NET_IP" || \
    -z "$ROLES" || \
    -z "$CIDR" || \
    -z "$QUORUM" ]]; then
  echo "Missing Parameter(s)"
  exit 1
fi

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILES_DIR="${SCRIPT_PATH}/../files"
INTERFACE=${MAIN_IF:-eth1}
NET_MASK=$(ifconfig "$INTERFACE" | sed -rn '2s/ .*:(.*)$/\1/p')

# Hosts arrays computation
IFS=' ' read -r -a CTRLNODES <<< "${CONTROLLERS}"
IFS=' ' read -r -a SLNODES <<< "${SLAVES}"
IFS=' ' read -r -a CEPHNODES <<< "${MONITORS}"

# Roles
IFS=' ' read -r -a SRVROLES <<< "${ROLES}"

. "${SCRIPT_PATH}"/properties.sh
. "${SCRIPT_PATH}"/functions.sh

HOSTNAME=$(get_property HOSTNAME)
RACK=$(get_property RACK)
UNIT=$(get_property UNIT)

ZK_HOSTS=$(get_property ZK_HOSTS)



CONTROLLER_ID=$(get_property CONTROLLER_ID)
CEPH_MON_ID=$(get_property CEPH_MON_ID)
CLUSTER=$(get_property CLUSTER)

PGNUM=$(get_property PGNUM)
NBMONS=$(get_property NBMONS)

function main(){

  echo ">>> Updating APT sources"
  call apt.sh

  echo ">>> Updating Hostname and /etc/hosts"
  call host.sh

  if has "QUAGGA" "${SRVROLES[@]}"; then
    echo ">>> Installing Quagga"
    call quagga.sh
  fi

  if has "PLENUM" "${SRVROLES[@]}"; then
    echo ">>> Installing Plenum"
    call plenum.sh
  fi

  echo ">>> Installing Docker"
  call docker.sh

  echo ">>> Installing Ceph client"
  call ceph.sh

  if has "REGISTRY" "${SRVROLES[@]}"; then
    echo ">>> Installing Docker Registry"
    call registry.sh
  fi

  if has "MON" "${SRVROLES[@]}"; then
    echo ">>> Installing Ceph Monitors"
    call ceph-mon.sh
  fi

  if has "OSD" "${SRVROLES[@]}"; then
    echo ">>> Installing Ceph OSDs"
    call ceph-osd.sh
  fi

  if has "MESOS-SLAVE" "${SRVROLES[@]}"; then
    echo ">>> Installing Mesos nodes"
    call mesos-slave.sh
  fi

  if has "ZK" "${SRVROLES[@]}"; then
    echo ">>> Installing Zookeeper"
    call zookeeper.sh
  fi

  if has "MESOS-MASTER" "${SRVROLES[@]}"; then
    echo ">>> Installing Mesos Master"
    call mesos-master.sh
  fi

  if has "AURORA" "${SRVROLES[@]}"; then
    echo ">>> Installing Aurora Scheduler"
    call aurora.sh
  fi
}

main "$@"