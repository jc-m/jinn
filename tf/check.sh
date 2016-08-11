#! /bin/bash
# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.
set -e

pass(){
  tput setaf 2
  # shellcheck disable=SC2059
  printf "${@}"
  tput sgr0
}
fail(){
  tput setaf 1
  # shellcheck disable=SC2059
  printf "${@}"
  tput sgr0
}
title(){
  tput bold
  # shellcheck disable=SC2059
  printf "${@}"
  tput sgr0
}

# shellcheck disable=SC2029
function vssh()
{
  local _vm=${1}
  shift 1
  ssh -o Compression=yes -o DSAAuthentication=yes -o LogLevel=FATAL \
       -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
       -o IdentitiesOnly=yes -i ${KEY} \
       "${USER}@${_vm}" "$@"
}

USER="ubuntu"
PROJECT="${DIR##*/}"

if [[ -z "$1" ]]; then
  echo "Please provide the utility instance public DNS name or IP"
  exit 1
fi

if [[ -z "$2" ]]; then
  echo "Please provide your private key file location"
  exit 1
fi

KEY=$2
VM=$1
title "\n\nChecking PLENUM routes \n"
zkhosts=()
mesos=()
aurora=()

routes=$(vssh "${VM}"  'ip route list proto bird' | awk '{print $1}')

while IFS= read -r ip; do
  IFS=. read -r i1 i2 i3 i4 <<< "$ip"

  if [[ -z "$i1" ]] || [[ -z "$i2" ]]; then
    exit 1
  fi
  if [[ "$i3" -eq "255" ]] ; then
    if [[ $ip == 192.168.255.* ]] && [[ "$i4" -gt "30" ]]; then
      zkhosts+=($ip)
    fi

    if [[ "$i4" -lt "20" ]] && [[ "$i1" -ne "192" ]]; then
      mesos+=($ip)
    fi

    if [[ "$i4" -lt "30" ]] && [[ "$i4" -gt "20" ]]; then
      aurora+=($ip)
    fi
  fi
  printf "%s\n" "$ip"
done <<< "$routes"

title "\nChecking Zookeeper \n"
(
  count=0
  mode=""
  for ip in "${zkhosts[@]-}"; do 
    # bash doesn't recognize empty arrays
    if [[ -n $ip ]]; then
      mode=$(vssh "${VM}" "echo stat | nc $ip 2181 | grep Mode")
      mode=${mode##*: }
      if [[ "${mode}" == "standalone" || "${mode}" == "leader" ]]; then
        (( count ++ ))
      fi
      printf "%s: %s\n" "$ip" "${mode}"
    fi
  done 
  if [ "$count" -lt "1" ]; then
    fail "No leader elected\n"
  else
    pass "leader elected\n"
  fi
)


title "\nChecking Mesos \n"
(
  count=0
  mode=""
  for ip in "${mesos[@]-}"; do 
    # bash doesn't recognize empty arrays
    if [[ -n $ip ]]; then
      mode=$(vssh "${VM}" "curl -s http://$ip:5050/metrics/snapshot | grep -oh elected\\\":1")
      mode=${mode##*:}
      if [ -n "$mode" ] && [ "${mode%.*}" -gt "0" ]; then
        printf "%s: %s\n" "$ip" "Leader"
        (( count ++ ))
      else
        printf "%s: %s\n" "$ip" "Not Leader"
      fi
    fi
  done 
  if [ "$count" -lt "1" ]; then
    fail "No leader elected\n"
  else
    pass "leader elected\n"
  fi

)


title "\nChecking Aurora \n"
(
  count=0
  mode=""
  for ip in "${aurora[@]-}"; do 
    # bash doesn't recognize empty arrays
    if [[ -n $ip ]]; then
      mode=$(vssh "${VM}" "curl -s http://$ip:8081/vars | grep framework_registered")
    fi
    if [ -n "$mode" ] && [ "${mode#* }" -gt "0" ]; then
      printf "%s: %s\n" "$ip" "Leader"
      (( count ++ ))
    else
      printf "%s: %s\n" "$ip" "Not Leader"
    fi
  done 
  if [ "$count" -lt "1" ]; then
    fail "No leader elected\n"
  else
    pass "leader elected\n"
  fi
)
printf "\n"
